module euler_volume_cylindrical_source
    use mod_kinds,              only: rk,ik
    use mod_constants,          only: ONE,TWO,HALF

    use type_operator,          only: operator_t
    use type_properties,        only: properties_t
    use type_chidg_worker,      only: chidg_worker_t
    use DNAD_D
    implicit none

    private

    
    !> Volume flux for Euler equations.
    !!
    !!  @author Nathan A. Wukie
    !!  @date   1/28/2016
    !!
    !!
    !------------------------------------------------------------------------------
    type, extends(operator_t), public :: euler_volume_cylindrical_source_t


    contains

        procedure   :: init
        procedure   :: compute

    end type euler_volume_cylindrical_source_t
    !******************************************************************************





contains


    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   8/29/2016
    !!
    !--------------------------------------------------------------------------------
    subroutine init(self)
        class(euler_volume_cylindrical_source_t),   intent(inout)      :: self

        ! Set operator name
        call self%set_name("Euler Volume Cylindrical Source")

        ! Set operator type
        call self%set_operator_type("Volume Advective Flux")

        ! Set operator equations
        call self%add_primary_field("Density"   )
        call self%add_primary_field("Momentum-1")
        call self%add_primary_field("Momentum-2")
        call self%add_primary_field("Momentum-3")
        call self%add_primary_field("Energy"    )

    end subroutine init
    !********************************************************************************



    !> Volume flux routine for Euler equations.
    !!
    !!  @author Nathan A. Wukie
    !!  @date   1/28/2016
    !!  
    !!
    !!------------------------------------------------------------------------------
    subroutine compute(self,worker,prop)
        class(euler_volume_cylindrical_source_t),   intent(inout)   :: self
        type(chidg_worker_t),                       intent(inout)   :: worker
        class(properties_t),                        intent(inout)   :: prop


        type(AD_D), allocatable, dimension(:) ::    &
            density, mom2, v, p, source 



        !
        ! Interpolate solution to quadrature nodes
        !
        density = worker%get_primary_field_element('Density'   ,'value')
        mom2    = worker%get_primary_field_element('Momentum-2','value')


        !
        ! Account for cylindrical. Get tangential velocity from angular momentum.
        !
        if (worker%coordinate_system() == 'Cylindrical') then
            v = (mom2/density) / worker%coordinate('1','volume')
        end if


        !
        ! Get pressure
        !
        p = worker%get_model_field_element('Pressure','value')


        !=================================================
        ! mass flux
        !=================================================


        !=================================================
        ! momentum-1 flux
        !=================================================
        source = (density*v*v + p) / worker%coordinate('1','volume')

        call worker%integrate_volume('Momentum-1',source)


        !=================================================
        ! momentum-2 flux
        !=================================================


        !=================================================
        ! momentum-3 flux
        !=================================================


        !=================================================
        ! energy flux
        !=================================================



    end subroutine compute
    !*********************************************************************************************************






end module euler_volume_cylindrical_source