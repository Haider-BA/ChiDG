module type_face_info
    use mod_kinds,  only: ik


    !> Container for locating a given face in the mesh data, via indices.
    !!
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/1/2016
    !!
    !!
    !----------------------------------------------------------------------------------
    type, public :: face_info_t

        integer(ik)     :: idomain_g
        integer(ik)     :: idomain_l
        integer(ik)     :: ielement_g
        integer(ik)     :: ielement_l
        integer(ik)     :: iface        !< Element-local face index

    end type face_info_t
    !**********************************************************************************





end module type_face_info
