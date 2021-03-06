module type_chidg_vector_recv_comm
#include <messenger.h>
    use mod_kinds,          only: ik
    use mod_constants,      only: INTERIOR, CHIMERA
    use type_mesh,          only: mesh_t
    use type_ivector,       only: ivector_t
    use type_blockvector,   only: blockvector_t
    use mod_chidg_mpi,      only: ChiDG_COMM
    use mpi_f08,            only: MPI_Recv, MPI_INTEGER4, MPI_STATUS_IGNORE, MPI_ANY_TAG
    implicit none


    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   6/30/2016
    !!
    !!
    !----------------------------------------------------------------------------
    type, public :: chidg_vector_recv_comm_t

        integer(ik)                         :: proc
        type(blockvector_t),    allocatable :: dom(:)

    contains

        procedure,  public  :: init
        procedure,  public  :: clear

    end type chidg_vector_recv_comm_t
    !****************************************************************************








contains




    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   6/30/2016
    !!
    !!
    !!
    !---------------------------------------------------------------------------------
    subroutine init(self,mesh,iproc,icomm)
        class(chidg_vector_recv_comm_t), intent(inout)   :: self
        type(mesh_t),                   intent(inout)   :: mesh(:)
        integer(ik),                    intent(in)      :: iproc
        integer(ik),                    intent(in)      :: icomm

        integer(ik)                 :: idom, idom_recv, ndom_recv, ierr, ielem, iface, ChiID, donor_domain_g, donor_element_g
        integer(ik)                 :: idomain_g, ielement_g, dom_store, idom_loop, ielem_loop, ielem_recv, nelem_recv
        integer(ik)                 :: neighbor_domain_g, neighbor_element_g, recv_element, recv_domain, idonor
        integer(ik),    allocatable :: comm_procs_dom(:)
        logical                     :: proc_has_domain, domain_found, element_found, comm_neighbor, has_neighbor, is_chimera, comm_donor, donor_recv_found

        !
        ! Set processor being received from
        !
        self%proc = iproc


        
        !
        ! Get number of domains being received from proc
        !
        call MPI_Recv(ndom_recv,1,MPI_INTEGER4,self%proc, MPI_ANY_TAG, ChiDG_COMM, MPI_STATUS_IGNORE, ierr)



        !
        ! Allocate number of recv domains to recv information from proc
        !
        if (allocated(self%dom)) deallocate(self%dom)
        allocate(self%dom(ndom_recv), stat=ierr)
        if (ierr /= 0) call AllocationError



        !
        ! Call initialization for each domain to be received
        !
        do idom_recv = 1,ndom_recv
            call self%dom(idom_recv)%init(iproc)
        end do ! idom





        !
        ! Loop through mesh and initialize recv indices
        !
        do idom = 1,size(mesh)
            do ielem = 1,mesh(idom)%nelem
                do iface = 1,size(mesh(idom)%faces,2)

                    has_neighbor = ( mesh(idom)%faces(ielem,iface)%ftype == INTERIOR )
                    is_chimera   = ( mesh(idom)%faces(ielem,iface)%ftype == CHIMERA  )


                    !
                    ! Initialize recv for comm interior neighbors
                    !
                    if (has_neighbor) then

                        comm_neighbor = (iproc == mesh(idom)%faces(ielem,iface)%ineighbor_proc)

                        ! If neighbor is being communicated, find it in the recv domains
                        if (comm_neighbor) then
                            neighbor_domain_g = mesh(idom)%faces(ielem,iface)%ineighbor_domain_g
                            neighbor_element_g = mesh(idom)%faces(ielem,iface)%ineighbor_element_g

                            ! Loop through domains being received to find the right domain
                            do idom_recv = 1,ndom_recv
                                recv_domain = self%dom(idom_recv)%vecs(1)%dparent_g()

                                if (recv_domain == neighbor_domain_g) then

                                    ! Loop through the elements in the recv domain to find the right neighbor element
                                    do ielem_recv = 1,size(self%dom(idom_recv)%vecs)
                                        recv_element = self%dom(idom_recv)%vecs(ielem_recv)%eparent_g()

                                        

                                        ! Set the location where a face can find its off-processor neighbor 
                                        if (recv_element == neighbor_element_g) then
                                            mesh(idom)%faces(ielem,iface)%recv_comm    = icomm
                                            mesh(idom)%faces(ielem,iface)%recv_domain  = idom_recv
                                            mesh(idom)%faces(ielem,iface)%recv_element = ielem_recv
                                        end if

                                    end do !ielem_recv

                                end if

                            end do !idom_recv

                        end if





                    !
                    ! Initialize recv for comm chimera receivers
                    !
                    else if (is_chimera) then
                        
                        ChiID = mesh(idom)%faces(ielem,iface)%ChiID
                        do idonor = 1,mesh(idom)%chimera%recv%data(ChiID)%ndonors()

                            comm_donor = (iproc == mesh(idom)%chimera%recv%data(ChiID)%donor_proc%at(idonor) )

                            donor_recv_found = .false.
                            if (comm_donor) then
                                donor_domain_g  = mesh(idom)%chimera%recv%data(ChiID)%donor_domain_g%at(idonor)
                                donor_element_g = mesh(idom)%chimera%recv%data(ChiID)%donor_element_g%at(idonor)


                                ! Loop through domains being received to find the right domain
                                do idom_recv = 1,ndom_recv
                                    recv_domain = self%dom(idom_recv)%vecs(1)%dparent_g()

                                    if (recv_domain == donor_domain_g) then

                                        ! Loop through the elements in the recv domain to find the right neighbor element
                                        do ielem_recv = 1,size(self%dom(idom_recv)%vecs)
                                            recv_element = self%dom(idom_recv)%vecs(ielem_recv)%eparent_g()


                                            ! Set the location where a face can find its off-processor neighbor 
                                            if (recv_element == donor_element_g) then
                                                mesh(idom)%chimera%recv%data(ChiID)%donor_recv_comm%data_(idonor)    = icomm
                                                mesh(idom)%chimera%recv%data(ChiID)%donor_recv_domain%data_(idonor)  = idom_recv
                                                mesh(idom)%chimera%recv%data(ChiID)%donor_recv_element%data_(idonor) = ielem_recv
                                                donor_recv_found = .true.
                                                exit
                                            end if

                                        end do !ielem_recv

                                    end if

                                    if (donor_recv_found) exit
                                end do !idom_recv

                                if (.not. donor_recv_found) call chidg_signal_three(FATAL,"chidg_vector_recv_comm%init: chimera receiver did not find parallel donor.",IRANK,donor_domain_g,donor_element_g)
                            end if !comm_donor


                        end do ! idonor

                    

                    end if



                end do ! iface
            end do ! ielem
        end do ! idom





    end subroutine init
    !*********************************************************************************










    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   7/7/2016
    !!
    !!
    !----------------------------------------------------------------------------------
    subroutine clear(self)
        class(chidg_vector_recv_comm_t), intent(inout)   :: self

        integer(ik) :: idom


        do idom = 1,size(self%dom)
            call self%dom(idom)%clear()
        end do


    end subroutine clear
    !**********************************************************************************







end module type_chidg_vector_recv_comm
