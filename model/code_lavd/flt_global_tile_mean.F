C $Header: net 6/5/17
C $Name: compute_global_mean

#include "CPP_OPTIONS.h"

CBOP 0
C !ROUTINE: FLT_LAVD

C !INTERFACE:

      SUBROUTINE GLOBAL_TILE_MEAN_RL (
     I                myNr, arr, arrMask, arrArea,
     I                myTime, myThid,
     O                meanOut)
C     !DESCRIPTION: \bv
C     /==========================================================\
C     | SUBROUTINE COMPUTE_GLOBAL_MEAN_RL                        |
C     | o Calculate the area wieghted global  mean of array      |
C     | "_RL arr"                                                |
C     |                                                          |
C     | o based on the code in remove_mean.F and mon_vort3.F     | 
C      \==========================================================/
C     \ev

      IMPLICIT NONE

C     === Global data ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"

C     === Functions ====
      LOGICAL  DIFFERENT_MULTIPLE
      EXTERNAL DIFFERENT_MULTIPLE

C     === Routine arguments ===
      INTEGER myNr
      _RL arr(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RS arrMask(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RS arrArea(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

      _RL myTime
      _RL meanOut
 
      INTEGER myThid

      
C#ifdef ALLOW_BALANCE_FLUXES
C     === Local variables ====
      INTEGER I,J,K,bi,bj

      _RL tileMean(nSx,nSy)
      _RL tileArea(nSx,nSy)

      _RL tmpArea
      _RL tmpVal

      _RL globalMean
      _RL globalArea
      
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      
      K = myNr

C     tileMean is named following convention which is
C     a bit confusing. It is not the mean, but the 
C     the numerator of the mean  = sum dArea * value 
      
C     loop over all the tile subgrids and construct tileArea
C     and tileMean
      
      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)
        tileMean(bi,bj) = 0
        tileArea(bi,bj) = 0
        tmpVal = 0
        tmpArea = 0
        DO J=1,sNy
         DO I=1,sNx
          IF (arrMask(I,J,K,bi,bj).NE.0.) THEN
           tmpVal=arr(I,J,K,bi,bj)
           tmpArea = arrArea(I,J,bi,bj)
           tileArea(bi,bj)  = tileArea(bi,bj)   + tmpArea
           tileMean(bi,bj)  = tileMean(bi,bj) + tmpArea*tmpVal
          ENDIF
         ENDDO
        ENDDO
       ENDDO
      ENDDO

C     sum results over all the tiles and processes
C     we have to pass the full tile array
C     this is why we call it after/ outside subgrid loop 
      CALL GLOBAL_SUM_TILE_RL( tileMean, globalMean, myThid) 
      CALL GLOBAL_SUM_TILE_RL( tileArea, globalArea, myThid)
      
C     output to help in debugging
C      DO bj=myByLo(myThid),myByHi(myThid)
C       DO bi=myBxLo(myThid),myBxHi(myThid)
C        WRITE(msgBuf,'(A)')
C     &    '----- DEBUG COMPUTE_GLOBAL_MEAN_RL -------- '
C        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &       SQUEEZE_RIGHT, myThid )
C
C        WRITE(msgBuf,'(A,I,A,E)')
C     &    'myThid= ', myThid, ' last temp area  =', tmpArea
C        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &                       SQUEEZE_RIGHT, myThid )
C         
C        WRITE(msgBuf,'(A,I,A,E)')
C     &    'myThid= ', myThid, ' last temp vorticity  =', tmpVal
C        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &                       SQUEEZE_RIGHT, myThid )
C         
C        WRITE(msgBuf,'(A,I,A,E)')
C     &    'myThid= ', myThid, ' subgrid vort*area =', tileMean(bi,bj)
C        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &                       SQUEEZE_RIGHT, myThid )
C
C        WRITE(msgBuf,'(A,I,A,E)')
C     &       'myThid= ', myThid, 'subgrid total area =', tileArea(bi,bj)
C        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &       SQUEEZE_RIGHT, myThid )
C
C        WRITE(msgBuf,'(A)')
C     &    '------ END DEBUG COMPUTE_GLOBAL_MEAN_RL -------- '
C        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &               SQUEEZE_RIGHT, myThid )
C       ENDDO
C      ENDDO
      
C now compute the actual global mean 
      IF (globalArea.GT.0.) THEN
       globalMean=globalMean/globalArea

      ENDIF

      meanOut = globalMean 

      RETURN
      END

