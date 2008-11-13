!***************************************************************************************************
! Copyright 2003, 2004, D. Boscher, S. Bourdarie
!
! This file is part of ONERA_DESP_LIB.
!
!    ONERA_DESP_LIB is free software: you can redistribute it and/or modify
!    it under the terms of the GNU Lesser General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    ONERA_DESP_LIB is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU Lesser General Public License for more details.
!
!    You should have received a copy of the GNU Lesser General Public License
!    along with ONERA_DESP_LIB.  If not, see <http://www.gnu.org/licenses/>.
!
C Boscher modifie pour la nieme fois le 4Feb2004
C
C
       SUBROUTINE calcul_Lstar(t_resol,r_resol,
     &         lati,longi,alti,Lm,Lstar,leI0,B0,Bmin)
C
       IMPLICIT NONE
       INCLUDE 'variables.inc'
C
       INTEGER*4  Nreb_def,Nder_def,Ntet_def
       PARAMETER (Nreb_def = 50, Nder_def = 25, Ntet_def = 720)
C
       INTEGER*4  Nder,Nreb,Ntet
       INTEGER*4  k_ext,k_l,kint,n_resol,t_resol,r_resol
       INTEGER*4  Nrebmax
       REAL*8     rr,rr2
       REAL*8     xx0(3),xx(3),x1(3),x2(3)
       REAL*8     xmin(3)
       REAL*8     lati,longi,alti
       REAL*8     B(3),Bl,B0,Bmin,B1,B3
       REAL*8     dsreb,smin

       INTEGER*4  I,J,Iflag,Iflag_I,Ilflag,Ifail
       REAL*8     Lm,Lstar,Lb
       REAL*8     leI,leI0,leI1
       REAL*8     XY,YY
       REAL*8     aa,bb
C
       REAL*8     pi,rad,tt
       REAL*8     tet(10*Nder_def),phi(10*Nder_def)
       REAL*8     tetl,tet1,dtet
       REAL*8     somme
C
       REAL*8     Bo,xc,yc,zc,ct,st,cp,sp
C
       COMMON /dipigrf/Bo,xc,yc,zc,ct,st,cp,sp
       COMMON /calotte/tet
       COMMON /flag_L/Ilflag
       COMMON /magmod/k_ext,k_l,kint
C
C
       Nder=Nder_def*r_resol
       Nreb=Nreb_def
       Ntet=Ntet_def*t_resol
       pi = 4.D0*ATAN(1.D0)
       rad = pi/180.D0
       dtet = pi/Ntet
C
       Nrebmax = 20*Nreb
C
       Lm = baddata
       Lstar = baddata
       leI0 = baddata
C
       CALL GDZ_GEO(lati,longi,alti,xx0(1),xx0(2),xx0(3))
C
       CALL GEO_SM(xx0,xx)
       rr = SQRT(xx(1)*xx(1)+xx(2)*xx(2)+xx(3)*xx(3))
       tt = ACOS(xx(3)/rr)
       Lb  = rr/SIN(tt)/SIN(tt)
c       write(6,*)'L bete ',Lb
C
       CALL CHAMP(xx0,B,B0,Ifail)
       IF (Ifail.LT.0) THEN
	  B0=baddata
          leI0 = baddata
          Bmin = baddata
          Ilflag = 0
	  RETURN
       ENDIF
       Bmin = B0
C
       dsreb = Lb/Nreb
C
C calcul du sens du depart
C
       CALL sksyst(-dsreb,xx0,x1,Bl,Ifail)
       IF (Ifail.LT.0) THEN
          leI0 = baddata
          Bmin = baddata
          Ilflag = 0
	  RETURN
       ENDIF
       B1 = Bl
       CALL sksyst(dsreb,xx0,x2,Bl,Ifail)
       IF (Ifail.LT.0) THEN
          leI0 = baddata
          Bmin = baddata
          Ilflag = 0
	  RETURN
       ENDIF
       B3 = Bl
C
C attention cas equatorial
C
       IF(B1.GT.B0 .AND. B3.GT.B0)THEN
         aa = 0.5D0*(B3+B1-2.D0*B0)
         bb = 0.5D0*(B3-B1)
         smin = -0.5D0*bb/aa
         Bmin = B0 - aa*smin*smin
         leI0 = SQRT(1.D0-Bmin/B0)*2.D0*ABS(smin*dsreb)
         Lm = (Bo/Bmin)**(1.D0/3.D0)
c         write(6,*)'L McIlwain eq ',B0,leI0,Lm
         GOTO 100
       ENDIF
       IF (B3.GT.B1) THEN
         dsreb = -dsreb
       ENDIF
C
C calcul de la ligne de champ et de I
C
       Bmin = B0
       leI = 0.D0
       DO I = 1,3
         x1(I)  = xx0(I)
       ENDDO
C
c       write(6,*)dsreb
       DO J = 1,Nrebmax
         CALL sksyst(dsreb,x1,x2,Bl,Ifail)
         IF (Ifail.LT.0) THEN
            leI0 = baddata
            Bmin = baddata
            Ilflag = 0
	    RETURN
	 ENDIF
c	 write(6,*)J,x1(1),x1(2),x1(3),Bl
         IF (Bl.LT.Bmin) THEN
           xmin(1) = x2(1)
           xmin(2) = x2(2)
           xmin(3) = x2(3)
           Bmin = Bl
         ENDIF
         IF (Bl.GT.B0) GOTO 20
	 x1(1) = x2(1)
	 x1(2) = x2(2)
	 x1(3) = x2(3)
         leI = leI + SQRT(1.D0-Bl/B0)
	 B1 = Bl
       ENDDO
20     CONTINUE
c	write(6,*)J,leI
C
       IF (J.GE.Nrebmax) THEN !open field line
          leI0 = baddata
          Bmin = baddata
          Ilflag = 0
	  RETURN
       ENDIF
C
       leI = leI+0.5D0*SQRT(1.D0-B1/B0)*(B0-Bl)/(Bl-B1)
       leI = leI*ABS(dsreb)
       leI0 = leI
C
C calcul de L Mc Ilwain (Mc Ilwain-Hilton)
C
       XY = leI*leI*leI*B0/Bo
       YY = 1.D0 + 1.35047D0*XY**(1.D0/3.D0)
     &      + 0.465376D0*XY**(2.D0/3.D0)
     &      + 0.0475455D0*XY
       Lm = (Bo*YY/B0)**(1.D0/3.D0)
c       write(6,*)'L McIlwain ',B0,leI0,Lm
C
C calcul de Bmin
C
       CALL sksyst(dsreb,xmin,x1,B3,Ifail)
       IF (Ifail.LT.0) THEN
          Bmin = baddata
          Ilflag = 0
	  RETURN
       ENDIF
       CALL sksyst(-dsreb,xmin,x1,B1,Ifail)
       IF (Ifail.LT.0) THEN
          Bmin = baddata
          Ilflag = 0
	  RETURN
       ENDIF
       aa = 0.5D0*(B3+B1-2.D0*Bmin)
       bb = 0.5D0*(B3-B1)
       smin = -0.5D0*bb/aa
       Bmin = Bmin - aa*smin*smin
       IF (x2(1)*x2(1)+x2(2)*x2(2)+x2(3)*x2(3).LT.1.D0) THEN
        Lm = -Lm
       ENDIF
C
100    CONTINUE
       if (k_l .eq.0) then
          Ilflag = 0
	  RETURN
       endif
       IF (ABS(Lm) .GT. 10.D0) THEN
        Ilflag = 0
        RETURN
       ENDIF
C
C derive
C
C
C calcul du point sur la ligne de champ a la surface de la terre du
C cote nord
C
       DO I = 1,3
         x1(I)  = xx0(I)
       ENDDO
       dsreb = ABS(dsreb)
       DO J = 1,Nrebmax
         CALL sksyst(dsreb,x1,x2,Bl,Ifail)
         IF (Ifail.LT.0) THEN
            Ilflag = 0
	    RETURN
	 ENDIF
	 rr = sqrt(x2(1)*x2(1)+x2(2)*x2(2)+x2(3)*x2(3))
	 IF (rr.LT.1.D0) GOTO 102
	 x1(1) = x2(1)
	 x1(2) = x2(2)
	 x1(3) = x2(3)
       ENDDO
102    CONTINUE
       smin = sqrt(x1(1)*x1(1)+x1(2)*x1(2)+x1(3)*x1(3))
       smin = (1.D0-smin)/(rr-smin)
       CALL sksyst(smin*dsreb,x1,x2,Bl,Ifail)
       IF (Ifail.LT.0) THEN
          Ilflag = 0
	  RETURN
       ENDIF
       rr = sqrt(x2(1)*x2(1)+x2(2)*x2(2)+x2(3)*x2(3))
       tet(1) = ACOS(x2(3)/rr)
       phi(1) = ATAN2(x2(2),x2(1))
C
C et on tourne -> on se decale sur la surface en phi et on cherche teta
C pour avoir leI0 et B0 constants
C
       dsreb = -dsreb
       DO I = 2,Nder
        phi(I) = phi(I-1)+2.D0*pi/Nder
        Iflag_I = 0
c	write(6,*)tet(I)
	IF (Ilflag.EQ.0) THEN
         tetl = tet(I-1)
	 IF (I.GT.2) tetl = 2.D0*tet(I-1)-tet(I-2)
         tet1 = tetl
	ELSE
	 tetl = tet(I)
	 tet1 = tetl
	ENDIF
c	write(6,*)tetl
c	read(5,*)
	leI1 = baddata
C
107     CONTINUE
        x1(1) = SIN(tetl)*COS(phi(I))
        x1(2) = SIN(tetl)*SIN(phi(I))
        x1(3) = COS(tetl)
        Iflag = 0
        leI = baddata
C
        DO J = 1,Nrebmax
         CALL sksyst(dsreb,x1,x2,Bl,Ifail)
         IF (Ifail.LT.0) THEN
            Ilflag = 0
	    RETURN
	 ENDIF
         rr2 = x2(1)*x2(1)+x2(2)*x2(2)+x2(3)*x2(3)
	 IF (Bl.LT.B0) THEN
	  IF (Iflag .EQ. 0) THEN
	    CALL CHAMP(x1,B,B1,Ifail)
	    IF (Ifail.LT.0) THEN
               Ilflag = 0
	       RETURN
	    ENDIF
	    leI = 0.5D0*SQRT(1.D0-Bl/B0)*(1.D0+(Bl-B0)/(Bl-B1))
	    Iflag = 1
	  ELSE
	    leI = leI+SQRT(1.D0-Bl/B0)
	  ENDIF
	 ENDIF
         IF (Bl.GT.B0 .AND. Iflag.EQ.1) GOTO 103
	 IF (rr2.LT.1.D0) GOTO 103
	 x1(1) = x2(1)
	 x1(2) = x2(2)
	 x1(3) = x2(3)
c	 write(6,*)J,Bl,B0,leI*ABS(dsreb)
        ENDDO
103     CONTINUE
c Pourquoi?
        IF (rr2.LT.1.D0) THEN
         leI = baddata
	ENDIF
        IF (J.LT.Nrebmax .AND. rr2.GE.1.D0) THEN
            CALL CHAMP(x1,B,B1,Ifail)
	    IF (Ifail.LT.0) THEN
               Ilflag = 0
	       RETURN
	    ENDIF
            leI = leI+0.5D0*SQRT(1.D0-B1/B0)*(B0-Bl)/(Bl-B1)
            leI = leI*ABS(dsreb)
	ENDIF
c	write(6,*)I,tetl,leI,leI0,J
C
        IF (Iflag_I .EQ.0) THEN
	 IF (J.GE.Nrebmax) THEN
	  tetl = tetl-dtet
         ELSE
	  tetl = tetl+dtet
	 ENDIF
	 leI1 = leI
	 tet1 = tetl
	 Iflag_I = 1
	 GOTO 107
	ENDIF
	IF ((leI-leI0)*(leI1-leI0) .LT. 0.D0) GOTO 108
	leI1 = leI
	tet1 = tetl
	IF (leI.LT.leI0) THEN
	 tetl = tetl-dtet
	ElSE
	 tetl = tetl+dtet
	ENDIF
	IF (tetl.GT.pi .OR. tetl.LT.0.D0) GOTO 108
	GOTO 107
108     CONTINUE
        tet(I) = 0.5D0*(tetl+tet1)
c	read(5,*)
	IF (J.GE.Nrebmax .AND. leI.GT.0.D0) THEN
	 Ilflag = 0
	 RETURN
	ENDIF
C
        x1(1) = SIN(tet(I))*COS(phi(I))
        x1(2) = SIN(tet(I))*SIN(phi(I))
        x1(3) = COS(tet(I))
	CALL CHAMP(x1,B,Bl,Ifail)
	IF (Ifail.LT.0) THEN
	   Ilflag = 0
	   RETURN
	ENDIF
	IF (Bl.LT.B0) THEN
	 Ilflag = 0
	 RETURN
	ENDIF
       ENDDO
c       write(6,*)(tet(I),I=1,Nder)
c       read(5,*)
C
C calcul de somme de BdS sur la calotte nord
C
       x1(1) = 0.D0
       x1(2) = 0.D0
       x1(3) = 1.D0
       CALL CHAMP(x1,B,Bl,Ifail)
       IF (Ifail.LT.0)THEN
	   Ilflag = 0
	   RETURN
       ENDIF
       somme = Bl*pi*dtet*dtet/4.D0
       DO I = 1,Nder
         tetl = 0.D0
         DO J = 1,Ntet
	  tetl = tetl+dtet
	  IF (tetl .GT. tet(I)) GOTO 111
          x1(1) = SIN(tetl)*COS(phi(I))
          x1(2) = SIN(tetl)*SIN(phi(I))
          x1(3) = COS(tetl)
          CALL CHAMP(x1,B,Bl,Ifail)
          IF (Ifail.LT.0)THEN
	      Ilflag = 0
	      RETURN
          ENDIF
	  somme = somme+Bl*SIN(tetl)*dtet*2.D0*pi/Nder
	 ENDDO
111      CONTINUE
       ENDDO
       if (k_l .eq.1) Lstar = 2.D0*pi*Bo/somme
       if (k_l .eq.2) Lstar = somme  ! Phi and not Lstar
       IF (Lm.LT.0.D0) Lstar = -Lstar
       Ilflag = 1
C
       END
C
C***********************************************************************
C* RUNGE-KUTTA d'ordre 4
C***********************************************************************
        SUBROUTINE sksyst(h,xx,x2,Bl,Ifail)
C
        IMPLICIT NONE
C
        INTEGER*4  Ifail
        REAL*8 xx(3),x2(3)
        REAL*8 B(3),Bl
        REAL*8 h
        REAL*8 xwrk(4,3)
C
C-----------------------------------------------------------------------
C
c        write(6,*)'sksyst'
c        write(6,*)xx(1),xx(2),xx(3),h
        CALL CHAMP(xx,B,Bl,Ifail)
c	write(6,*)xx,B,Bl,Ifail
	IF (Ifail.LT.0) RETURN
c        write(6,*)'b',B(1),B(2),B(3),Bl
        xwrk(1,1) = h*B(1)/Bl
        xwrk(1,2) = h*B(2)/Bl
        xwrk(1,3) = h*B(3)/Bl
        x2(1) = xx(1)+xwrk(1,1)/2.D0
        x2(2) = xx(2)+xwrk(1,2)/2.D0
        x2(3) = xx(3)+xwrk(1,3)/2.D0
c        write(6,*)x2(1),x2(2),x2(3),Bl
C
        CALL CHAMP(x2,B,Bl,Ifail)
	IF (Ifail.LT.0) RETURN
        xwrk(2,1) = h*B(1)/Bl
        xwrk(2,2) = h*B(2)/Bl
        xwrk(2,3) = h*B(3)/Bl
        x2(1) = xx(1)+xwrk(2,1)/2.D0
        x2(2) = xx(2)+xwrk(2,2)/2.D0
        x2(3) = xx(3)+xwrk(2,3)/2.D0
c        write(6,*)x2(1),x2(2),x2(3),Bl
C
        CALL CHAMP(x2,B,Bl,Ifail)
	IF (Ifail.LT.0) RETURN
        xwrk(3,1) = h*B(1)/Bl
        xwrk(3,2) = h*B(2)/Bl
        xwrk(3,3) = h*B(3)/Bl
        x2(1) = xx(1)+xwrk(3,1)
        x2(2) = xx(2)+xwrk(3,2)
        x2(3) = xx(3)+xwrk(3,3)
c        write(6,*)x2(1),x2(2),x2(3),Bl
C
        CALL CHAMP(x2,B,Bl,Ifail)
	IF (Ifail.LT.0) RETURN
        xwrk(4,1) = h*B(1)/Bl
        xwrk(4,2) = h*B(2)/Bl
        xwrk(4,3) = h*B(3)/Bl
C
C-----------------------------------------------------------------------
C
        x2(1) = xx(1)+(   xwrk(1,1)+2.D0*xwrk(2,1)
     &               + 2.D0*xwrk(3,1)+   xwrk(4,1))/6.D0
        x2(2) = xx(2)+(   xwrk(1,2)+2.D0*xwrk(2,2)
     &               + 2.D0*xwrk(3,2)+   xwrk(4,2))/6.D0
        x2(3) = xx(3)+(   xwrk(1,3)+2.D0*xwrk(2,3)
     &               + 2.D0*xwrk(3,3)+   xwrk(4,3))/6.D0
        CALL CHAMP(x2,B,Bl,Ifail)
	IF (Ifail.LT.0) RETURN
c        write(6,*)x2(1),x2(2),x2(3),Bl
c        read(5,*)
C
        RETURN
        END


