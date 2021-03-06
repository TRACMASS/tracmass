SUBROUTINE read_field

  !==========================================================================
  !
  ! Purpose
  ! -------
  !
  ! Read test model output to advect trajectories.
  ! Will be called by the loop each time step.
  !
  ! Method
  ! ------
  !
  ! Read velocities and optionally some tracers from netCDF files and
  ! update velocity fields for TRACMASS.
  !
  ! Updates the variables:
  !   uflux and vflux
  ! ==========================================================================


   USE mod_precdef
   USE mod_param
   USE mod_vel
   USE mod_time
   USE mod_grid
   USE mod_getfile
   USE mod_swap

   USE netcdf

   IMPLICIT none

   INTEGER               :: ii, jj, ip, jp

   REAL(DP)              :: FillValue = -214748

   CHARACTER (len=200)   :: fieldFile, dateprefix

   ! Reassign the time index of uflux and vflux
   CALL swap_time()

   ! Data files
   dateprefix = filledFileName(dateFormat, currYear, currMon, currDay)
   fieldFile = TRIM(physDataDir)//TRIM(physPrefixForm)//TRIM(dateprefix)//TRIM(fileSuffix)

   uvel(1:imt,1:jmt,1) = get2DfieldNC(fieldFile, ueul_name,[imindom,jmindom,1,1],[imt,jmt,1,1],'st')
   vvel(1:imt,1:jmt,1) = get2DfieldNC(fieldFile, veul_name,[imindom,jmindom,1,1],[imt,jmt,1,1],'st')

   ! uvel, vvel come on an A grid, so we need to interpolate to
   !! staggered C grid
   DO ii = 1 , imt
      ip = ii+1
      IF (ii == imt) ip = 1

      DO jj = 1, jmt
         jp = jj+1
         IF (jj == jmt) jp=jmt

         uflux(ii,jj,1,2) =  0.5 * (uvel(ii,jj,1) + uvel(ip,jj,1)) &
                              * dyu(ii,jj) * dzt(ii,jj,1,nsp)
         vflux(ii,jj,1,2) =  0.5 * (vvel(ii,jj,1) + vvel(ii,jp,1)) &
                              * dxv(ii,jj) * dzt(ii,jj,1,nsp)

         ! Avoid fluxes through walls
         IF (uvel(ii,jj,1) <= FillValue .OR. uvel(ip,jj,1) <= FillValue) uflux(ii,jj,1,2) = 0.d0
         IF (vvel(ii,jj,1) <= FillValue .OR. vvel(ii,jp,1) <= FillValue) vflux(ii,jj,1,2) = 0.d0
      END DO
   END DO

   !! Zero meridional flux at j=0 and j=jmt
   vflux(:,0  ,:,:) = 0.d0
   vflux(:,jmt,:,:) = 0.d0

   ! Reverse the sign of fluxes if trajectories are run backward in time.
   CALL swap_sign()

END SUBROUTINE read_field
