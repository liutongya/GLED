C $Header: /u/gcmpack/MITgcm/pkg/flt/flt_traj.F,v 1.14 2012/03/30 18:25:03 jmc Exp $
C $Name:  $

#include "FLT_OPTIONS.h"

CBOP 0
C !ROUTINE: FLT_TRAJ

C !INTERFACE:
      SUBROUTINE FLT_TRAJ (
     I                      myTime, myIter, myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE FLT_TRAJ
C     | o This routine samples the model state at float position
C     |   every flt_int_traj time steps and writes output.
C     *==========================================================*

C     !USES:
      IMPLICIT NONE
C     == global variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "FLT_SIZE.h"
#include "FLT.h"
#include "FLT_BUFF.h"
#include "GRID.h"
#ifdef ALLOW_EXCH2
#include "W2_EXCH2_SIZE.h"
#include "W2_EXCH2_TOPOLOGY.h"
#endif

C     !INPUT PARAMETERS:
C     myTime :: current time in simulation
C     myIter :: current iteration number
C     myThid :: my Thread Id number
      _RL myTime
      INTEGER myIter, myThid

C     !FUNCTIONS:
      _RL FLT_MAP_K2R
      EXTERNAL FLT_MAP_K2R

C     !LOCAL VARIABLES:
      INTEGER bi, bj, nFlds
      INTEGER ip, kp, ii
      INTEGER i, j
      INTEGER iG, jG
      _RL ix, jy,  xx, yy, zz
      _RL uu, vv, tt, ss, pp
C     relative vorticity on float position
      _RL vo
C     relative vorticity (Eulerian field)
      _RL vort3(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr, nSx, nSy)
      _RS hFacZ(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      _RS r_hFacZ(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
          
      INTEGER imax
      PARAMETER (imax=14)
      _RL tmp(imax)
      _RL npart_read, npart_times
      _RS dummyRS(1)
      INTEGER fp, ioUnit, irecord
      CHARACTER*(MAX_LEN_FNAM) fn
      CHARACTER*(MAX_LEN_MBUF) msgBuf
#ifdef ALLOW_EXCH2
      INTEGER nT
#endif
CEOP

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C--   set number of fields to write
      nFlds = 8
C      IF ( flt_selectTrajOutp.GE.1 ) nFlds = nFlds + 8
C      IF ( flt_selectTrajOutp.GE.2 ) nFlds = nFlds + 5
C-- RPA hack: output vorticity
C      IF ( flt_selectTrajOutp.GE.3 ) nFlds = nFlds + 1

C--   check buffer size
      IF ( nFlds.GT.fltBufDim ) THEN
         _BEGIN_MASTER(myThid)
         WRITE(msgBuf,'(3(A,I4))') ' FLT_TRAJ: fltBufDim=', fltBufDim,
     &                             ' too small (<', nFlds, ' )'
         CALL PRINT_ERROR( msgBuf, myThid )
         WRITE(msgBuf,'(2A)')     ' FLT_TRAJ: => increase fltBufDim',
     &                            ' in "FLT_SIZE.h" & recompile'
         CALL PRINT_ERROR( msgBuf, myThid )
         _END_MASTER(myThid)
         CALL ALL_PROC_DIE( myThid )
         STOP 'ABNORMAL END: S/R FLT_TRAJ'
      ENDIF

C -- will eliminating this break something?
C      IF ( myIter.EQ.nIter0 .OR. flt_selectTrajOutp.LE.0 ) RETURN

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
C--   Calculate position + other fields at float position and fill up IO-buffer

      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)

C#ifdef ALLOW_EXCH2
C         nT = W2_myTileList(bi,bj)
C         i0x = DFLOAT( exch2_txGlobalo(nT) - 1 )
C         j0y = DFLOAT( exch2_tyGlobalo(nT) - 1 )
C#else
C         i0x = DFLOAT( myXGlobalLo-1 + (bi-1)*sNx )
C         j0y = DFLOAT( myYGlobalLo-1 + (bj-1)*sNy )
C#endif
         IF ( flt_selectTrajOutp.GE.3 ) THEN
C --     Calculate relative vorticity
           DO kp = 1,Nr
             CALL MOM_CALC_HFACZ( bi,bj,kp,hFacZ,r_hFacZ,myThid )
             CALL MOM_CALC_RELVORT3( bi, bj, kp,
     &                                 uVel, vVel, hFacZ,
     &                                 vort3(1-OLx,1-OLy,kp, bi, bj),
     &                                 myThid)
             DO j=1-OLy,sNy+OLy
              DO i=1-OLx,sNx+OLx
                IF ( hFacZ(i,j).EQ.0. ) THEN
                  vort3(i,j,kp, bi, bj)  = 0. _d 0
                ENDIF
              ENDDO
             ENDDO
           ENDDO
         ENDIF

         DO ip=1,npart_tile(bi,bj)

            ix = ipart(ip,bi,bj)
            jy = jpart(ip,bi,bj)
            CALL FLT_MAP_IJLOCAL2XY( xx, yy,
     I                               ix, jy, bi,bj, myThid )
            zz = FLT_MAP_K2R( kpart(ip,bi,bj),bi,bj,myThid )
            kp = NINT(kpart(ip,bi,bj))
C            tmp(1) = DBLE(npart(ip,bi,bj))
            tmp(1) = myTime
            tmp(2) = xx
            tmp(3) = yy
            tmp(4) = zz
C            tmp(6) = ix + i0x
C            tmp(7) = jy + j0y
C            tmp(8) = kpart(ip,bi,bj)

C            IF ( ( flt_selectTrajOutp.GE.2 )   .AND.
C     &           ( myTime.GE.tstart(ip,bi,bj)) .AND.
C     &           ( tend(ip,bi,bj).EQ.-1. .OR. myTime.LE.tend(ip,bi,bj))
C     &         ) THEN
C              IF ( kp.LT.1 .OR. kp.GT.Nr ) THEN
C                WRITE(msgBuf,'(2A,I8)') '** WARNING ** FLT_TRAJ: ',
C     &            ' illegal value for kp=',kp
C                CALL PRINT_MESSAGE( msgBuf, errorMessageUnit,
C     &                              SQUEEZE_RIGHT, myThid )
C                WRITE(msgBuf,'(A,1P5E20.13)')
C     &            ' FLT_TRAJ: ', (flt_io_buff(ii,ip,bi,bj),ii=1,5)
C                CALL PRINT_MESSAGE( msgBuf, errorMessageUnit,
C     &                              SQUEEZE_RIGHT, myThid )
c               CALL PRINT_ERROR( msgBuf, myThid )
c               STOP 'ABNORMAL END: S/R FLT_TRAJ'
C-- jmc: not sure if this is right but added to avoid Pb in FLT_BILINEAR:
C                kp = MIN( MAX(kp,1), Nr)
C              ENDIF
             
            kp = MIN( MAX(kp,1), Nr)
            CALL FLT_BILINEAR  (ix,jy,uu,uVel,  kp,1,bi,bj,myThid)
            CALL FLT_BILINEAR  (ix,jy,vv,vVel,  kp,2,bi,bj,myThid)
C              CALL FLT_BILINEAR2D(ix,jy,pp,etaN,     0,bi,bj,myThid)
C              CALL FLT_BILINEAR  (ix,jy,tt,theta, kp,0,bi,bj,myThid)
C              CALL FLT_BILINEAR  (ix,jy,ss,salt,  kp,0,bi,bj,myThid)
C              tmp( 9) = pp
            tmp(5) = uu
            tmp(6) = vv
C              tmp(12) = tt
C              tmp(13) = ss
              
C-- RPA hack: calculate relative vorticity
            CALL FLT_BILINEAR(ix,jy,vo,vort3, kp, 4,bi,bj,myThid)
            tmp(7) = vo
             
              
C            ELSEIF ( flt_selectTrajOutp.GE.2 ) THEN
C              tmp( 9) = flt_nan
C              tmp(10) = flt_nan
C              tmp(11) = flt_nan
C              tmp(12) = flt_nan
C              tmp(13) = flt_nan
C              tmp(14) = flt_nan
C            ENDIF
C---Nathaniel Hack: output lavd
            tmp(8) = lavd(ip,bi,bj)
            DO ii=1,nFlds
              flt_io_buff(ii,ip,bi,bj) = tmp(ii)
            ENDDO

         ENDDO

       ENDDO
      ENDDO

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C--   Write shared buffer to file

      _BARRIER
      _BEGIN_MASTER(myThid)
 
      fp = writeBinaryPrec

      DO bj=1,nSy
       DO bi=1,nSx

         IF (npart_tile(bi,bj) .GE. 1) THEN
           iG=bi+(myXGlobalLo-1)/sNx
           jG=bj+(myYGlobalLo-1)/sNy
           WRITE(fn,'(A,I10.10,A,I3.3,A,I3.3,A)') 'float_trajectories.',
     &           myIter, '.', iG, '.', jG, '.csv' 
           OPEN(33333, FILE=fn, ACCESS='APPEND', ACTION='WRITE',
     &          STATUS='REPLACE')
C-- write out header           
           WRITE(33333, '(9A)') 
     &          'npart,', 'time,', 'x,', 'y,', 'z,', 'u,', 'v,',
     &          'vort,', 'lavd'
C-- write out data
           DO ip=1,npart_tile(bi,bj)
             WRITE(33333, '(I, 99(A, E))') npart(ip,bi,bj),
     &                (',', flt_io_buff(ii,ip,bi,bj), ii=1, nFlds)
           ENDDO
           CLOSE(33333)
         ENDIF

       ENDDO
      ENDDO

      _END_MASTER(myThid)
      _BARRIER

      RETURN
      END
