C $Header: 1.0  2017/6/1 net $
C $Name: flt_lavd $

#include "FLT_OPTIONS.h"

CBOP 0
C !ROUTINE: FLT_LAVD

C !INTERFACE:
      SUBROUTINE FLT_LAVD (
     I                      myTime, myIter, myThid )

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE FLT_LAVD
C     | o This routine computes the LAVD field for each particle 
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

C     === Routie Arguments ===
C     myTime :: current time in simulation
C     myIter :: current iteration number
C     myThid :: my Thread Id number
      _RL myTime
      INTEGER myIter, myThid

C     === Local Variables === 
      INTEGER bi, bj
      INTEGER ip, kp
      INTEGER i, j
      _RL ix, jy 
      
C     relative vorticity on float position
      _RL vo
C     relative vorticity (Eulerian field)
      _RL vort3(1-OLx:sNx+OLx, 1-OLy:sNy+OLy, Nr, nSx, nSy)
      _RS hFacZ(1-OLx:sNx+OLx, 1-OLy:sNy+OLy)
      _RS r_hFacZ(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      
C     the global mean vort at depth Nr  and inst. vorticity deviation 
      _RL mean_vort(Nr) 
      _RL ivd

      CHARACTER*(MAX_LEN_MBUF) msgBuf

CEOP

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C--   loop over all the subgrids and compute the vorticity field
      
      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)

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
                  vort3(i,j,kp,bi,bj)  = 0. _d 0
                ENDIF
              ENDDO
             ENDDO
           ENDDO
         ENDIF
       ENDDO
      ENDDO



C--   use subroutine written by NET  to compute area-weighted average
C--   over all processes and tiles for each depth level kp
C--   for reference, the declaration is 
C--   SUBROUTINE GLOBAL_TILE_MEAN_RL (
C--   I                myNr, arr, arrMask, arrArea,
C--   I                myTime, myThid,
C--   O                meanOut)
      
      DO kp = 1,Nr
         CALL GLOBAL_TILE_MEAN_RL(kp, vort3, maskInC, rA,
     &        myTime, myThid, mean_vort(kp))
C--  output global mean to STDOUT for reference
C         WRITE(msgBuf,'(A,I,A,F)')
C     &    'at kp=',kp,' global mean vorticity =', mean_vort(kp)
C         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &                       SQUEEZE_RIGHT, myThid )
      ENDDO

C--   loop over all subgrids and compute lavd for each particle
      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)
        DO ip=1,npart_tile(bi,bj)
            ix = ipart(ip,bi,bj)
            jy = jpart(ip,bi,bj)
            kp = NINT(kpart(ip,bi,bj))
              
            CALL FLT_BILINEAR(ix,jy,vo,vort3, kp, 4,bi,bj,myThid)

            ivd = ABS(vo-mean_vort(kp)) 

            lavd(ip,bi,bj) = ( ivd*flt_deltaT +
     &      (myTime - flt_deltaT)*lavd(ip,bi,bj) )/myTime
        ENDDO
       ENDDO
      ENDDO

      RETURN

      END
