module fluid_viscous_volume_operator
    use mod_kinds,              only: rk,ik
    use mod_constants,          only: ONE,TWO,HALF

    use type_operator,          only: operator_t
    use type_properties,        only: properties_t
    use type_chidg_worker,      only: chidg_worker_t
    use DNAD_D
    implicit none

    private

    
    !> Volume flux for Fluid Viscous Terms.
    !!
    !!  @author Nathan A. Wukie
    !!  @date   9/23/2016
    !!
    !!
    !------------------------------------------------------------------------------
    type, extends(operator_t), public :: fluid_viscous_volume_operator_t


    contains

        procedure   :: init
        procedure   :: compute

    end type fluid_viscous_volume_operator_t
    !******************************************************************************










contains


    !>
    !!
    !!  @author Nathan A. Wukie (AFRL)
    !!  @date   9/23/2016
    !!
    !--------------------------------------------------------------------------------
    subroutine init(self)
        class(fluid_viscous_volume_operator_t),   intent(inout)      :: self

        ! Set operator name
        call self%set_name("Fluid Viscous Volume Operator")

        ! Set operator type
        call self%set_operator_type("Volume Diffusive Operator")

        ! Set operator equations
        call self%add_primary_field("Density"   )
        call self%add_primary_field("X-Momentum")
        call self%add_primary_field("Y-Momentum")
        call self%add_primary_field("Z-Momentum")
        call self%add_primary_field("Energy"    )

    end subroutine init
    !********************************************************************************



    !> Volume flux routine for Fluid Viscous Terms.
    !!
    !!  @author Nathan A. Wukie
    !!  @date   9/23/2016
    !!  
    !!
    !!------------------------------------------------------------------------------
    subroutine compute(self,worker,prop)
        class(fluid_viscous_volume_operator_t), intent(inout)   :: self
        type(chidg_worker_t),                   intent(inout)   :: worker
        class(properties_t),                    intent(inout)   :: prop

        type(AD_D), allocatable, dimension(:) ::                                &
            rho, rhou, rhov, rhow, rhoE, p, T, u, v, w, invrho, mu, lamda, k,   &
            mu_l, mu_t, lamda_l, lamda_t, k_l, k_t,                             &
            drho_dx, drhou_dx, drhov_dx, drhow_dx, drhoE_dx,                    &
            drho_dy, drhou_dy, drhov_dy, drhow_dy, drhoE_dy,                    &
            drho_dz, drhou_dz, drhov_dz, drhow_dz, drhoE_dz,                    &
            du_dx,   dv_dx,    dw_dx,    dT_dx,                                 &
            du_dy,   dv_dy,    dw_dy,    dT_dy,                                 &
            du_dz,   dv_dz,    dw_dz,    dT_dz,                                 &
            du_drho, du_drhou, dv_drho,  dv_drhov, dw_drho, dw_drhow,           &
            dT_drho, dT_drhou, dT_drhov, dT_drhow, dT_drhoE,                    &
            dp_drho, dp_drhou, dp_drhov, dp_drhow, dp_drhoE,                    &
            dke_drho, dke_drhou, dke_drhov, dke_drhow,                          &
            tau_xx, tau_yy, tau_zz, tau_xy, tau_xz, tau_yz,                     &
            flux_x, flux_y, flux_z

        real(rk)    :: const, gam


        !
        ! Interpolate solution to quadrature nodes
        !
        rho  = worker%get_primary_field_element("Density"   ,'value')
        rhou = worker%get_primary_field_element("X-Momentum",'value')
        rhov = worker%get_primary_field_element("Y-Momentum",'value')
        rhow = worker%get_primary_field_element("Z-Momentum",'value')
        rhoE = worker%get_primary_field_element("Energy"    ,'value')



        !
        ! Interpolate solution gradients to quadrature nodes
        !
        drho_dx  = worker%get_primary_field_element("Density"   ,'ddx+lift')
        drho_dy  = worker%get_primary_field_element("Density"   ,'ddy+lift')
        drho_dz  = worker%get_primary_field_element("Density"   ,'ddz+lift')

        drhou_dx = worker%get_primary_field_element("X-Momentum",'ddx+lift')
        drhou_dy = worker%get_primary_field_element("X-Momentum",'ddy+lift')
        drhou_dz = worker%get_primary_field_element("X-Momentum",'ddz+lift')

        drhov_dx = worker%get_primary_field_element("Y-Momentum",'ddx+lift')
        drhov_dy = worker%get_primary_field_element("Y-Momentum",'ddy+lift')
        drhov_dz = worker%get_primary_field_element("Y-Momentum",'ddz+lift')

        drhow_dx = worker%get_primary_field_element("Z-Momentum",'ddx+lift')
        drhow_dy = worker%get_primary_field_element("Z-Momentum",'ddy+lift')
        drhow_dz = worker%get_primary_field_element("Z-Momentum",'ddz+lift')

        drhoE_dx = worker%get_primary_field_element("Energy"    ,'ddx+lift')
        drhoE_dy = worker%get_primary_field_element("Energy"    ,'ddy+lift')
        drhoE_dz = worker%get_primary_field_element("Energy"    ,'ddz+lift')



        !
        ! Get Model fields:
        !   Pressure
        !   Temperature
        !   Viscosity
        !   Second Coefficient of Viscosity
        !   Thermal Conductivity
        !
        p       = worker%get_model_field_element('Pressure',                                  'value')
        T       = worker%get_model_field_element('Temperature',                               'value')
        mu_l    = worker%get_model_field_element('Laminar Viscosity',                         'value')
        mu_t    = worker%get_model_field_element('Turbulent Viscosity',                       'value')
        lamda_l = worker%get_model_field_element('Second Coefficient of Laminar Viscosity',   'value')
        lamda_t = worker%get_model_field_element('Second Coefficient of Turbulent Viscosity', 'value')
        k_l     = worker%get_model_field_element('Laminar Thermal Conductivity',              'value')
        k_t     = worker%get_model_field_element('Turbulent Thermal Conductivity',            'value')
        gam = 1.4_rk


        !
        ! Compute effective viscosities, conductivity. Laminar + Turbulent.
        !
        mu    = mu_l    + mu_t
        lamda = lamda_l + lamda_t
        k     = k_l     + k_t



        !
        ! Compute velocities
        !
        invrho = ONE/rho
        u = rhou*invrho
        v = rhov*invrho
        w = rhow*invrho


        !
        ! Compute velocity jacobians
        !
        du_drho  = -invrho*invrho*rhou
        du_drhou =  invrho

        dv_drho  = -invrho*invrho*rhov
        dv_drhov =  invrho

        dw_drho  = -invrho*invrho*rhow
        dw_drhow =  invrho



        !
        ! Compute Kinetic Energy Jacobians
        !
        dke_drho  = -HALF*(u*u + v*v + w*w)
        dke_drhou = u
        dke_drhov = v
        dke_drhow = w


        !
        ! Compute Pressure Jacobians
        !
        dp_drho  = -(gam-ONE)*dke_drho
        dp_drhou = -(gam-ONE)*dke_drhou
        dp_drhov = -(gam-ONE)*dke_drhov
        dp_drhow = -(gam-ONE)*dke_drhow
        dp_drhoE =  dp_drhow    ! Initialize derivatives
        dp_drhoE =  (gam-ONE)   ! No negative sign

        
        !
        ! Compute Temperature Jacobians
        !
        const = ONE/287.15_rk
        dT_drho  = const*invrho*dp_drho  -  const*invrho*invrho*p
        dT_drhou = const*invrho*dp_drhou
        dT_drhov = const*invrho*dp_drhov
        dT_drhow = const*invrho*dp_drhow
        dT_drhoE = const*invrho*dp_drhoE



        !
        ! Compute velocity gradients
        !
        du_dx = du_drho*drho_dx  +  du_drhou*drhou_dx
        du_dy = du_drho*drho_dy  +  du_drhou*drhou_dy
        du_dz = du_drho*drho_dz  +  du_drhou*drhou_dz

        dv_dx = dv_drho*drho_dx  +  dv_drhov*drhov_dx
        dv_dy = dv_drho*drho_dy  +  dv_drhov*drhov_dy
        dv_dz = dv_drho*drho_dz  +  dv_drhov*drhov_dz

        dw_dx = dw_drho*drho_dx  +  dw_drhow*drhow_dx
        dw_dy = dw_drho*drho_dy  +  dw_drhow*drhow_dy
        dw_dz = dw_drho*drho_dz  +  dw_drhow*drhow_dz



        !
        ! Compute temperature gradient
        !
        dT_dx = dT_drho*drho_dx + dT_drhou*drhou_dx + dT_drhov*drhov_dx + dT_drhow*drhow_dx + dT_drhoE*drhoE_dx
        dT_dy = dT_drho*drho_dy + dT_drhou*drhou_dy + dT_drhov*drhov_dy + dT_drhow*drhow_dy + dT_drhoE*drhoE_dy
        dT_dz = dT_drho*drho_dz + dT_drhou*drhou_dz + dT_drhov*drhov_dz + dT_drhow*drhow_dz + dT_drhoE*drhoE_dz


        !
        ! Compute shear stress components
        !
        tau_xx = TWO*mu*du_dx  +  lamda*(du_dx + dv_dy + dw_dz)
        tau_yy = TWO*mu*dv_dy  +  lamda*(du_dx + dv_dy + dw_dz)
        tau_zz = TWO*mu*dw_dz  +  lamda*(du_dx + dv_dy + dw_dz)

        tau_xy = mu*(du_dy + dv_dx)
        tau_xz = mu*(du_dz + dw_dx)
        tau_yz = mu*(dw_dy + dv_dz)



        !===========================
        !        MASS FLUX
        !===========================


        !===========================
        !     X-MOMENTUM FLUX
        !===========================
        flux_x = -tau_xx
        flux_y = -tau_xy
        flux_z = -tau_xz

        call worker%integrate_volume('X-Momentum',flux_x,flux_y,flux_z)

        !============================
        !     Y-MOMENTUM FLUX
        !============================
        flux_x = -tau_xy
        flux_y = -tau_yy
        flux_z = -tau_yz

        call worker%integrate_volume('Y-Momentum',flux_x,flux_y,flux_z)

        !============================
        !     Z-MOMENTUM FLUX
        !============================
        flux_x = -tau_xz
        flux_y = -tau_yz
        flux_z = -tau_zz

        call worker%integrate_volume('Z-Momentum',flux_x,flux_y,flux_z)

        !============================
        !       ENERGY FLUX
        !============================
        !flux_x = -(1003._rk*mu/0.8_rk)*dT_dx  -  (u*tau_xx + v*tau_xy + w*tau_xz)
        !flux_y = -(1003._rk*mu/0.8_rk)*dT_dy  -  (u*tau_xy + v*tau_yy + w*tau_yz)
        !flux_z = -(1003._rk*mu/0.8_rk)*dT_dz  -  (u*tau_xz + v*tau_yz + w*tau_zz)
        flux_x = -k*dT_dx  -  (u*tau_xx + v*tau_xy + w*tau_xz)
        flux_y = -k*dT_dy  -  (u*tau_xy + v*tau_yy + w*tau_yz)
        flux_z = -k*dT_dz  -  (u*tau_xz + v*tau_yz + w*tau_zz)

        call worker%integrate_volume('Energy',flux_x,flux_y,flux_z)

    end subroutine compute
    !*********************************************************************************************************






end module fluid_viscous_volume_operator
