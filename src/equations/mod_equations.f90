!>
!!
!!  @author Nathan A. Wukie
!!  @date   2/8/2016
!!
!!
!!
!--------------------------------------------------------------------------------------------------
module mod_equations
#include <messenger.h>
    use mod_kinds,              only: rk,ik
    use mod_string,             only: string_t
    use type_equation_set,      only: equation_set_t
    use type_equation_builder,  only: equation_builder_t
    use type_evector,           only: evector_t

    !
    ! Import Equations
    !
    use eqn_scalar_advection,       only: scalar_advection
    use eqn_scalar_diffusion,       only: scalar_diffusion
    use eqn_dual_linear_advection,  only: dual_linear_advection
    use eqn_euler,                  only: euler 
    use eqn_navier_stokes,          only: navier_stokes
    use eqn_wall_distance,          only: wall_distance
    implicit none




    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   9/19/2016
    !!
    !!
    !--------------------------------------------------------------------------------------
    type, public :: equation_builder_factory_t

        type(evector_t) :: builders

    contains
        
        procedure   :: register
        procedure   :: produce => build_equation_set

    end type equation_builder_factory_t
    !**************************************************************************************




    type(equation_builder_factory_t)    :: equation_builder_factory
    logical                             :: initialized = .false.



contains


    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   9/19/2016
    !!
    !!
    !--------------------------------------------------------------------------------------
    subroutine register(self,builder)
        class(equation_builder_factory_t),  intent(inout)   :: self
        class(equation_builder_t),          intent(in)      :: builder

        call self%builders%push_back(builder)

    end subroutine register
    !***************************************************************************************










    !>  Register equation builders in a module vector. This is called from chidg%init('env').
    !!
    !!  This allows the available equations to be queried in the same way that they 
    !!  are registered for allocation.
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/8/2016
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   9/2/2016
    !!  @note   Modified to take equation_builder's instead of equation_set's
    !!
    !-----------------------------------------------------------------------------------
    subroutine register_equation_builders()
        integer :: ibuild

        !
        ! Instantiate Equations
        !
        type(scalar_advection)      :: scalar_advection_builder
        type(scalar_diffusion)      :: scalar_diffusion_builder
        type(dual_linear_advection) :: dual_linear_advection_builder
        type(euler)                 :: euler_builder
        type(navier_stokes)         :: navier_stokes_builder
        type(wall_distance)         :: wall_distance_builder


        !
        ! Register if needed
        !
        if ( .not. initialized ) then

            ! Register in global vector
            call equation_builder_factory%register(scalar_advection_builder)
            call equation_builder_factory%register(scalar_diffusion_builder)
            call equation_builder_factory%register(dual_linear_advection_builder)
            call equation_builder_factory%register(euler_builder)
            call equation_builder_factory%register(navier_stokes_builder)
            call equation_builder_factory%register(wall_distance_builder)




            ! Initialize each builder
            do ibuild = 1,equation_builder_factory%builders%size()
                call equation_builder_factory%builders%data(ibuild)%bld%init()
            end do

            ! Confirm initialization
            initialized = .true.

        end if

    end subroutine register_equation_builders
    !*************************************************************************************







    !>  EquationSet Factory
    !!      - procedure for allocating a concrete instance of an equationset_t
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/8/2016
    !!
    !!  @param[in] eqnstring    Character string for the equation set name
    !!  @param[in] eqnset       Allocatable equationset_t class to be instantiated
    !!
    !-------------------------------------------------------------------------------------
    function build_equation_set(self,eqnstring,blueprint) result(eqnset)
        class(equation_builder_factory_t),  intent(inout)   :: self
        character(len=*),                   intent(in)      :: eqnstring
        character(len=*),                   intent(in)      :: blueprint

        character(len=:),           allocatable :: user_msg, dev_msg
        integer                                 :: ierr, bindex
        type(equation_set_t)                    :: eqnset
        class(equation_builder_t), allocatable  :: builder

        !
        ! Find equation set in 'available_equations' vector
        !
        bindex = self%builders%index_by_name(eqnstring)


        !
        ! Check equationset was found in 'available_equations'
        !
        user_msg = "We can't seem to find an equation set that matches the string that was passed &
                    into the equation set factory. &
                    Maybe check that the equation set strings that were set for the domains &
                    are all valid."
        dev_msg = "Check that the equation set builder is registered properly in &
                   the equation set builder factory: src/equations/mod_equations.f90. When an equation &
                   set builder is defined, is needs to be registered in the factory by calling &
                   'call equation_builder_factory%register(builder)', where 'builder' is the &
                   object that knows how to build the equation set. This could be done in  &
                   'mod_equations.register_equation_builders'. The 'register_equation_builders' routine &
                   gets called on startup and loads all the default equation builders into the factory &
                   so the library knows what equation sets it can build."
        if (bindex == 0) call chidg_signal_two(OOPS,user_msg,trim(eqnstring),dev_msg=dev_msg)


        !
        ! Get equation set builder
        !
        allocate(builder, source=self%builders%at(bindex), stat=ierr)
        if (ierr /= 0) call AllocationError


        !
        ! Build equation set
        !
        eqnset = builder%build(blueprint)


    end function build_equation_set
    !*************************************************************************************








    !>  This is really a utilitity for 'chidg edit' to dynamically list the avalable 
    !!  equation sets.
    !!
    !!  @author Nathan A. Wukie
    !!  @date   2/8/2016
    !!
    !--------------------------------------------------------------------------------------
    subroutine list_equations()
        integer :: neqns, ieqn
        character(len=:),   allocatable :: ename
        
        neqns = equation_builder_factory%builders%size()

        do ieqn = 1,neqns

            ename = equation_builder_factory%builders%data(ieqn)%bld%get_name()
            call write_line(trim(ename))

        end do ! ieqn

    end subroutine list_equations
    !**************************************************************************************


















end module mod_equations
