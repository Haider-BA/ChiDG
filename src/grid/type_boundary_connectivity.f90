module type_boundary_connectivity
#include <messenger.h>
    use mod_kinds,              only: ik
    use type_face_connectivity, only: face_connectivity_t
    implicit none



    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   6/10/2016
    !!
    !!
    !------------------------------------------------------------------------------
    type, public :: boundary_connectivity_t

        type(face_connectivity_t),  allocatable :: data(:)

    contains
        
        procedure   :: init

!        procedure   :: get_domain_index         !< Return the global domain index
!        procedure   :: get_element_index        !< Return the index of a given element
!        procedure   :: get_element_mapping      !< Return the mapping of a given element
!        procedure   :: get_element_partition    !< Return the partition index that contains a given element
!        procedure   :: get_element_connectivity !< Return entire element_connectivity_t instance for given element
!        procedure   :: get_element_node         !< Return a given node for a given element
!        procedure   :: get_element_nodes        !< Return the array of nodes for a given element
        procedure   :: get_nfaces            !< Return the number of elements in the domain
!        procedure   :: get_nnodes               !< Return the number of unique nodes in the domain

    end type boundary_connectivity_t
    !*******************************************************************************


contains



    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   6/8/2016
    !!
    !!  @param[in]  nfaces  Number of faces in the connectivity
    !!
    !--------------------------------------------------------------------------------
    subroutine init(self,nfaces)
        class(boundary_connectivity_t), intent(inout)   :: self
        integer(ik),                    intent(in)      :: nfaces
        
        integer(ik) :: ierr

        allocate(self%data(nfaces), stat=ierr)
        if (ierr /= 0) call AllocationError

    end subroutine init
    !********************************************************************************








!    !>  Return the element index from a connectivity
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   6/10/2016
!    !!
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_domain_index(self) result(idomain)
!        class(domain_connectivity_t),  intent(in)  :: self
!
!        integer(ik) :: idomain
!
!        idomain = self%idomain_g
!
!    end function get_domain_index
!    !********************************************************************************
!
!
!
!
!
!
!
!
!
!    !>  Return the domain-global element index from a connectivity
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   6/10/2016
!    !!
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_element_index(self,idx) result(ielem)
!        class(domain_connectivity_t),   intent(in)  :: self
!        integer(ik),                    intent(in)  :: idx
!
!        integer(ik) :: ielem
!
!        !ielem = self%data(idx,1)
!        ielem = self%data(idx)%get_element_index()
!
!    end function get_element_index
!    !********************************************************************************
!
!
!
!
!
!
!
!
!
!    !>  Return the element mapping from a connectivity
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   6/10/2016
!    !!
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_element_mapping(self,idx) result(mapping)
!        class(domain_connectivity_t),  intent(in)  :: self
!        integer(ik),            intent(in)  :: idx
!
!        integer(ik) :: mapping
!
!        !mapping = self%data(idx,2)
!        mapping = self%data(idx)%get_element_mapping()
!
!    end function get_element_mapping
!    !********************************************************************************
!
!
!
!
!
!
!
!
!
!
!
!    !>  Return the element mapping from a connectivity
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   5/23/2016
!    !!
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_element_partition(self,idx) result(ipartition)
!        class(domain_connectivity_t),  intent(in)  :: self
!        integer(ik),            intent(in)  :: idx
!
!        integer(ik) :: ipartition
!
!        ipartition = self%data(idx)%get_element_partition()
!
!    end function get_element_partition
!    !********************************************************************************
!
!
!
!
!
!    !>  Return an entire element_connectivity_t instance for a given element
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   6/10/2016
!    !!
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_element_connectivity(self,idx) result(element_connectivity)
!        class(domain_connectivity_t),   intent(in)  :: self
!        integer(ik),                    intent(in)  :: idx
!
!        type(element_connectivity_t)    :: element_connectivity
!
!        element_connectivity = self%data(idx)
!
!    end function get_element_connectivity
!    !********************************************************************************
!
!
!
!
!
!    !>  Return a given node for a given element
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   6/10/2016
!    !!
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_element_node(self,idx_elem,idx_node) result(node)
!        class(domain_connectivity_t),   intent(in)  :: self
!        integer(ik),                    intent(in)  :: idx_elem
!        integer(ik),                    intent(in)  :: idx_node
!
!        integer(ik) :: node
!
!        node = self%data(idx_elem)%get_element_node(idx_node)
!
!    end function get_element_node
!    !********************************************************************************
!
!
!
!    !>  Return the array of nodes for a given element
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   6/10/2016
!    !!
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_element_nodes(self,idx_elem) result(nodes)
!        class(domain_connectivity_t),   intent(in)  :: self
!        integer(ik),                    intent(in)  :: idx_elem
!
!        integer(ik), allocatable :: nodes(:)
!
!        nodes = self%data(idx_elem)%get_element_nodes()
!
!    end function get_element_nodes
!    !********************************************************************************







    !>  Return the number of faces in the connectivity structure.
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   6/8/2016
    !!
    !!
    !--------------------------------------------------------------------------------
    function get_nfaces(self) result(nfaces)
        class(boundary_connectivity_t),  intent(in)  :: self

        integer(ik) :: nfaces

        nfaces = size(self%data)

    end function get_nfaces
    !********************************************************************************













!    !>  Return the number of unique node indices that are included in the 
!    !!  connectivity structure
!    !!
!    !!  @author Nathan A. Wukie (AFRL)
!    !!  @date   6/10/2016
!    !!
!    !!
!    !--------------------------------------------------------------------------------
!    function get_nnodes(self) result(nnodes)
!        class(domain_connectivity_t),  intent(in)  :: self
!
!        integer(ik)                 :: nnodes
!
!        nnodes = self%nnodes
!
!    end function get_nnodes
!    !********************************************************************************
!
!
!
!
!
!
!
!
!
!
!
!!    !>  Return the number of unique node indices that are included in the 
!!    !!  connectivity structure
!!    !!
!!    !!  @author Nathan A. Wukie (AFRL)
!!    !!  @date   6/8/2016
!!    !!
!!    !!
!!    !--------------------------------------------------------------------------------
!!    function get_nnodes(self) result(nnodes)
!!        class(domain_connectivity_t),  intent(in)  :: self
!!
!!        integer(ik)                 :: nnodes, min_index, max_index, ierr, ind, header
!!
!!        header = self%header_size
!!
!!        !
!!        ! Get maximum node index
!!        !
!!        max_index = maxval(self%data(:,header+1:))
!!        min_index = minval(self%data(:,header+1:))
!!
!!
!!
!!        nnodes = 0
!!        do ind = min_index,max_index
!!
!!            if ( any(self%data(:,header+1:) == ind ) ) then
!!                nnodes = nnodes + 1
!!            end if
!!
!!        end do
!!
!!    end function get_nnodes
!!    !********************************************************************************
!!
!
!
!
!
!
!
!
!



end module type_boundary_connectivity
