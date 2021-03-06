module mod_gridgen_cylinder
#include <messenger.h>
    use mod_kinds,              only: rk, ik
    use mod_constants,          only: PI, ZERO, ONE, TWO, THREE, HALF
    use mod_string,             only: string_t
    use mod_bc,                 only: create_bc
    use type_bc_state,          only: bc_state_t
    use type_bc_group,          only: bc_group_t
    use mod_plot3d_utilities,   only: get_block_points_plot3d, get_block_elements_plot3d, &
                                      get_block_boundary_faces_plot3d
    use mod_hdf_utilities,      only: add_domain_hdf, initialize_file_hdf, open_domain_hdf, &
                                      close_domain_hdf, add_bc_state_hdf, open_file_hdf,    &
                                      close_file_hdf, close_hdf, set_bc_patch_hdf,          &
                                      set_contains_grid_hdf, open_bc_group_hdf,             &
                                      close_bc_group_hdf, set_bc_patch_group_hdf, create_bc_group_hdf
    use hdf5

    use type_point,             only: point_t
    use type_bc_state,          only: bc_state_t
    use type_bc_state_wrapper,  only: bc_state_wrapper_t
    implicit none





contains




    !>  Create a grid representing a circular cylinder. Block boundaries
    !!  Are generally along the diagonals.
    !!
    !!  A value for block overlap(overlap_deg) can be passed to the routine that 
    !!  overlaps the blocks along the cylinder boundary. The outer corners
    !!  of the blocks are still coincident.
    !!
    !!      overlap_deg = 0.0   (No Overlap  : Abutting Blocks )
    !!      overlap_deg = 2.5   (Overlapping : Single Donor    )
    !!      overlap_deg = 5.0   (Overlapping : Multiple Donors )
    !!
    !!  The grid is generated by creating a block that represents a quarter
    !!  of the cylinder. This block is then replicated and rotated to
    !!  represent the rest of the cylinder.
    !!
    !!  Blocks 1-4
    !!
    !!                       Wall
    !!                   .---------.                   Single-block orientation
    !!                   |\   3   /|                           
    !!                   |  \ _ /  |                           ETA_MAX
    !!            Inlet  |4  (_)  2|  Outlet                      _     
    !!                   |  /   \  |                    XI_MIN  /   \   XI_MAX
    !!                   |/   1   \|                          /   1   \ 
    !!                   .---------.                         .---------.
    !!                       Wall                              ETA_MIN
    !!
    !!
    !!  @author Nathan A. Wukie 
    !!  @date   10/18/2016
    !!
    !!
    !----------------------------------------------------------------------------
    subroutine create_mesh_file__cylinder(filename,overlap_deg,equation_sets, group_names, bc_groups)
        character(*),               intent(in)              :: filename
        real(rk),                   intent(in)              :: overlap_deg
        type(string_t),             intent(in), optional    :: equation_sets(:)
        type(string_t),             intent(in), optional    :: group_names(:,:)
        type(bc_group_t),           intent(in), optional    :: bc_groups(:)

        integer(ik) :: npt_xi, npt_eta, npt_zeta, &
                       nelem_xi, nelem_eta, nelem_zeta, &
                       i,j,k,n, ierr, ncoords, ipt_xi, ipt_eta, ipt_zeta, &
                       bcface, idomain, spacedim, igroup, istate

        real(rk),   allocatable :: coords(:,:,:,:)
        real(rk)                :: x, y, z, alpha
        character(len=100)      :: domainname
        character(8)            :: face_strings(6)
        character(:),   allocatable :: user_msg

        real(rk)                :: xcenter, ycenter, zcenter, cradius, &
                                   xmin, xmax, ymin, ymax, zmin, zmax, &
                                   thetamin, thetamax, theta, clustering_factor, &
                                   rotated_x, rotated_y, rotated_z, overlap_rad

        real(rk),   allocatable, dimension(:)   :: xupper, yupper, xlower, ylower

        integer(HID_T)                  :: file_id, dom_id, bcface_id, bcgroup_id
        class(bc_state_t),  allocatable :: inlet, outlet, wall
        type(point_t),      allocatable :: nodes(:)
        integer(ik),        allocatable :: elements(:,:), faces(:,:)


        !
        ! Set geometry parameters
        !
        xcenter = 0._rk
        ycenter = 0._rk
        zcenter = 0._rk
        cradius = 0.5_rk
        xmin = -2._rk
        xmax = 2._rk
        ymin = -2._rk
        ymax = 2._rk
        zmin = 0._rk
        zmax = 1._rk


        !
        ! Set element resolution
        !
        nelem_xi = 6
        nelem_eta = 6
        nelem_zeta = 1


        !
        ! Set number of points
        !
        npt_xi   = nelem_xi*4 + 1
        npt_eta  = nelem_eta*4 + 1
        npt_zeta = nelem_zeta*4 + 1


        !
        ! Allocate coordinate array
        !
        allocate(coords(npt_xi,npt_eta,npt_zeta,3), stat=ierr)
        if (ierr /= 0) call AllocationError


        !
        ! Generate upper and lower curves
        !
        overlap_rad = overlap_deg * PI / 180._rk
        thetamin = ((THREE*PI/TWO) + ONE*PI) / TWO  -  overlap_rad
        thetamax = ((THREE*PI/TWO) + TWO*PI) / TWO  +  overlap_rad
        allocate(xupper(npt_xi), yupper(npt_xi), xlower(npt_xi), ylower(npt_xi), stat=ierr)
        if (ierr /= 0) call AllocationError
        

        do ipt_xi = 1,npt_xi
            xlower(ipt_xi) = xmin + real(ipt_xi-1,rk)*((xmax-xmin) / real(npt_xi-1,rk))
            ylower(ipt_xi) = ymin

            theta = thetamin + real(ipt_xi-1,rk)*( (thetamax-thetamin) / real(npt_xi-1,rk))
            xupper(ipt_xi) = cradius * dcos(theta)
            yupper(ipt_xi) = cradius * dsin(theta)
        end do




        !
        ! Generate coordinates
        !
        do ipt_zeta = 1,npt_zeta
            do ipt_eta = 1,npt_eta
                do ipt_xi = 1,npt_xi

                    clustering_factor = (real(ipt_eta,rk)/real(npt_eta,rk))**(-HALF)

                    x = xlower(ipt_xi) + (clustering_factor)*real(ipt_eta-1,rk)*((xupper(ipt_xi)-xlower(ipt_xi)) / real(npt_eta-1,rk))
                    y = ylower(ipt_xi) + (clustering_factor)*real(ipt_eta-1,rk)*((yupper(ipt_xi)-ylower(ipt_xi)) / real(npt_eta-1,rk))
                    z = ZERO + real(ipt_zeta-1,rk)*(ONE / real(npt_zeta-1,rk))

                    coords(ipt_xi,ipt_eta,ipt_zeta,1) = x
                    coords(ipt_xi,ipt_eta,ipt_zeta,2) = y
                    coords(ipt_xi,ipt_eta,ipt_zeta,3) = z

                end do !ipt_xi
            end do !ipt_eta
        end do !ipt_zeta





        ! Create boundary conditions
        call create_bc("Total Inlet", inlet)
        call create_bc("Pressure Outlet", outlet)
        call create_bc("Wall", wall)


        ! Set bc parameters
        call inlet%set_fcn_option("Total Pressure","val",110000._rk)
        call inlet%set_fcn_option("Total Temperature","val",300._rk)
        call outlet%set_fcn_option("Static Pressure","val",100000._rk)

        



        ! Create/initialize file
        call initialize_file_hdf(filename)
        file_id = open_file_hdf(filename)





        !
        ! Add bc_group's
        !
        if (present(bc_groups)) then

            do igroup = 1,size(bc_groups)
                call create_bc_group_hdf(file_id,bc_groups(igroup)%name)

                bcgroup_id = open_bc_group_hdf(file_id,bc_groups(igroup)%name)

                do istate = 1,bc_groups(igroup)%bc_states%size()
                    call add_bc_state_hdf(bcgroup_id, bc_groups(igroup)%bc_states%at(istate))
                end do
                call close_bc_group_hdf(bcgroup_id)
            end do


        else

            call create_bc_group_hdf(file_id,'Inlet')
            call create_bc_group_hdf(file_id,'Outlet')
            call create_bc_group_hdf(file_id,'Walls')

            bcgroup_id = open_bc_group_hdf(file_id,'Inlet')
            call add_bc_state_hdf(bcgroup_id,inlet)
            call close_bc_group_hdf(bcgroup_id)

            bcgroup_id = open_bc_group_hdf(file_id,'Outlet')
            call add_bc_state_hdf(bcgroup_id,outlet)
            call close_bc_group_hdf(bcgroup_id)

            bcgroup_id = open_bc_group_hdf(file_id,'Walls')
            call add_bc_state_hdf(bcgroup_id,wall)
            call close_bc_group_hdf(bcgroup_id)

        end if







        !
        ! Write domain, rotate, write domain, rotate, etc.
        !
        do idomain = 1,4

            !
            ! Get nodes/elements
            !
            nodes    = get_block_points_plot3d(coords(:,:,:,1),coords(:,:,:,2),coords(:,:,:,3))
            elements = get_block_elements_plot3d(coords(:,:,:,1),coords(:,:,:,2),coords(:,:,:,3),mapping=4,idomain=idomain)

            !
            ! Add domains
            !
            spacedim = 3
            write(domainname, '(I2.2)') idomain
            call add_domain_hdf(file_id,trim(domainname),nodes,elements,"Euler",spacedim)



            !
            ! Set boundary conditions patch connectivities
            !
            dom_id = open_domain_hdf(file_id,trim(domainname))

            do bcface = 1,6
                ! Get face node indices for boundary 'bcface'
                faces = get_block_boundary_faces_plot3d(coords(:,:,:,1),coords(:,:,:,2),coords(:,:,:,3),mapping=4,bcface=bcface)

                ! Set bc patch face indices
                call set_bc_patch_hdf(dom_id,faces,bcface)
            end do !bcface



            !
            ! Set all boundary conditions to walls, inlet, outlet...
            !
            ! No bc on "XI_MIN/XI_MAX" => Chimera
            !
            face_strings = ["XI_MIN  ","XI_MAX  ", "ETA_MIN ", "ETA_MAX ", "ZETA_MIN", "ZETA_MAX"]
            do bcface = 1,size(face_strings)

                call h5gopen_f(dom_id,"BoundaryConditions/"//trim(adjustl(face_strings(bcface))),bcface_id,ierr)

                if ( (idomain == 2) .and. (face_strings(bcface) == "ETA_MIN ") ) then
                    call set_bc_patch_group_hdf(bcface_id,"Outlet")
                else if ( (idomain == 4) .and. (face_strings(bcface) == "ETA_MIN ") ) then
                    call set_bc_patch_group_hdf(bcface_id,"Inlet")
                else if ( (face_strings(bcface) /= "XI_MIN  ") .and. (face_strings(bcface) /= "XI_MAX  ") ) then
                    call set_bc_patch_group_hdf(bcface_id,"Walls")
                end if

                call h5gclose_f(bcface_id,ierr)

            end do


            call close_domain_hdf(dom_id)


            !
            ! Rotate coordinates
            !
            do ipt_zeta = 1,npt_zeta
                do ipt_eta = 1,npt_eta
                    do ipt_xi = 1,npt_xi

                        ! Rotate coordinate
                        rotated_x = coords(ipt_xi,ipt_eta,ipt_zeta,1)*dcos(PI/2._rk) - &
                                    coords(ipt_xi,ipt_eta,ipt_zeta,2)*dsin(PI/2._rk)
                        rotated_y = coords(ipt_xi,ipt_eta,ipt_zeta,1)*dsin(PI/2._rk) + &
                                    coords(ipt_xi,ipt_eta,ipt_zeta,2)*dcos(PI/2._rk)
                        rotated_z = coords(ipt_xi,ipt_eta,ipt_zeta,3)

                        ! Store rotated coordinate
                        coords(ipt_xi,ipt_eta,ipt_zeta,1) = rotated_x
                        coords(ipt_xi,ipt_eta,ipt_zeta,2) = rotated_y
                        coords(ipt_xi,ipt_eta,ipt_zeta,3) = rotated_z

                    end do !ipt_xi
                end do !ipt_eta
            end do !ipt_zeta



        end do !idomain





        ! Set 'Contains Grid'
        call set_contains_grid_hdf(file_id,"True")



        call close_file_hdf(file_id)
        call close_hdf()


    end subroutine create_mesh_file__cylinder
    !****************************************************************************














end module mod_gridgen_cylinder
