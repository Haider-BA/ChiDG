module mod_equations
#include <messenger.h>
    use mod_kinds,                      only: rk,ik
    use atype_equationset,              only: equationset_t

    ! Import Equations
    use eqn_scalar,                     only: scalar_e
    use eqn_linearadvection,            only: linearadvection_e
    implicit none

    ! Instantiate Equations
    type(scalar_e)          :: SCALAR
    type(linearadvection_e) :: LINEARADVECTION


    logical :: uninitialized = .true.


contains


    subroutine initialize_equations()


        if (uninitialized) then
            ! List of equations to initialize
            call SCALAR%init()
            call LINEARADVECTION%init()

        end if

        uninitialized = .false.
    end subroutine





    !>  EquationSet Factory
    !!      - procedure for allocating a concrete instance of an equationset_t
    !!
    !!  @author Nathan A. Wukie
    !!
    !!  @param[in] eqnstring    Character string for the equation set name
    !!  @param[in] eqnset       Allocatable equationset_t class to be instantiated
    !-------------------------------------------------------------------------------------
    subroutine create_equationset(eqnstring,eqnset)
        character(*),                      intent(in)      :: eqnstring
        class(equationset_t), allocatable, intent(inout)   :: eqnset



        select case (trim(eqnstring))
            case ('scalar','Scalar')
                allocate(eqnset, source=SCALAR)

            case ('linearadvection','LinearAdvection','la','LA')
                allocate(eqnset, source=LINEARADVECTION)

            case default
                call signal(FATAL,'create_equationset -- equation string not recognized')
        end select

    end subroutine



end module mod_equations
