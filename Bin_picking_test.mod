MODULE Module1

    PERS tooldata tGripper :=[TRUE,[[0,0,510],[0.241576,0.00117355,0.000136995,0.970381]],[20,[0,0,400],[1,0,0,0],0,0,0]];
    PERS wobjdata wBpCalibration := [FALSE,TRUE,"",[[1747.6,354.153,494.523],[0.356431,0.0209332,0.0362679,0.933383]],[[0,0,0],[1,0,0,0]]];
    CONST robtarget rBpPickNoOffset:=[[0,0,0],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget rAboveBox:=[[-43.15,601.91,594.56],[0.0039395,-0.908162,-0.418584,0.00359836],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

    CONST robtarget Home:=[[524.584,1228.139,1077.999],[1,0,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget Drop:=[[0,0,0],[0,1,0,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PERS robtarget Pickup:=[[400,203.768,444.562],[-0.015035,0.706118,0.699947,-0.106047],[-1,0,1,0],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];

    PROC main()
        !Use this function when connected to Mabema to get coordinates of scanned pieces
        !GetCoordinates;
        VAR pose poseBpPos:=[[400,203.768,444.562],[-0.015035,0.706118,0.699947,-0.106047]];
        
        !GetPartBox rAboveBox, rBpPickNoOffset, tGripper, wBpPallet, wBpCalibration, poseBpPos;
        
        ! Adjust the pickup location according to the pose from Mabema
        Pickup.trans.x := poseBpPos.trans.x;
        Pickup.trans.y := poseBpPos.trans.y;
        Pickup.trans.z := poseBpPos.trans.z;
        Pickup.rot := poseBpPos.rot;
        
        ! Move the robot to pickup the scanned part and drop it to the drop point
        MoveJ Home,v500,z100,tGroup1gripperTool\WObj:=wobj0;
        MoveJ Offs(Pickup,0,0,100),v500,fine,currentTool\WObj:=Workobject_6;
        MoveJ Pickup,v200,fine,currentTool\WObj:=Workobject_6;
        MoveJ Offs(Pickup,0,0,100),v500,fine,currentTool\WObj:=Workobject_6;
        MoveJ Offs(Drop,0,0,300),v500,fine,currentTool\WObj:=Workobject_4;
        MoveJ Drop,v200,fine,currentTool\WObj:=Workobject_4;
        MoveJ Offs(Drop,0,0,100),v500,fine,currentTool\WObj:=Workobject_4;
        MoveJ Home,v500,z100,tGroup1gripperTool\WObj:=wobj0;
        
    ENDPROC

    PROC GetCoordinates()
        VAR pose poseBpPos;
        VAR SensActiveCom comBp;
        VAR string sBpIp := "127.0.0.1:5001";  !TODO
        VAR pose poseBp;
        ![[9.70406,203.768,444.562],[-0.015035,0.706118,0.699947,-0.106047]]  returned from mabema 20.11
        !testi


        IF (SensActiveInit(comBp)=FALSE AND SensActiveOpen(comBp,sBpIp,\nTimeout:=6)) THEN

            ! Check if the BP system is running.
            ! If it is stop it so we can change model
            IF (BpIsRunning(comBp) = TRUE) THEN
                IF (BpStop(comBp) = FALSE) THEN
                    TPWrite "Failed to stop BP system";
                    Stop;
                ENDIF
            ENDIF

            ! Set modelset
            IF (BpSetModelSet(comBp, "test") = FALSE) THEN   !TODO
                TPWrite "Failed to set modelset";
                Stop;
            ENDIF

            ! Start BP
            IF (BpStart(comBp) = FALSE) THEN
                TPWrite "Failed to start BP system";
                Stop;
            ENDIF

            ! Wait for scan to finish and then check if we found anything
            ! If we did. Go pick it up.
            IF BpIsScanFinished(comBp\WaitForResults\nTimeout:=60) THEN
                !
                WHILE BpObjectReady(comBp) DO
                    IF BpGetPick(comBp, poseBp) THEN
                        TPWrite "poseBp";
                        ! Advance the BP queue
                        IF BpNextPick(comBp) = FALSE THEN
                            TPWrite "Failed to advance the BP parts queue";
                            Stop;
                        ENDIF
                        
                        Stop;
                        ! TODO Do something with the part
                        TPWrite "poseBp";
                    ENDIF
                ENDWHILE
            ELSE
                TPWrite "Timeout while waiting for scan to finish";
                Stop;
            ENDIF
            
        ENDIF
        SensActiveClose comBp;
    ENDPROC

    PROC GetPartBox(robtarget rAboveBox, robtarget rBpPick, PERS tooldata tTool,PERS wobjdata wobjBox,PERS wobjdata wobjBP,pose pBP_Position)
        VAR bool bIgnore;
        VAR robtarget rAbovePickIn;
        VAR robtarget rAbovePickOut;
        VAR robtarget rPick;
        VAR pose pPick;
        VAR pos pPickOffset;
        !
        ConfJ\On;
        MoveJ rAboveBox,v2500,z200,tTool\WObj:=wobjBox;

        ! Grab position from BP and put it in the BP oframe
        ! so that the combined uframe*oframe is at the carrier
        ! picking position
        wobjBp.oframe:=pBP_Position;

        ! Convert picking position from BP coordinates to pallet coordinates
        rAbovePickIn:=UtlRobtargetFrameConv(RelTool(rBpPick,0,0,-100),wobjBp,wobjBox);
        rPick:=UtlRobtargetFrameConv(RelTool(rBpPick,0,0,0),wobjBp,wobjBox);

        pPickOffset.x:=(rAboveBox.trans.x-rPick.trans.x)*0.05;
        pPickOffset.y:=(rAboveBox.trans.y-rPick.trans.y)*0.05;
        pPickOffset.z:=100;

        rAbovePickOut:=Offs(rPick,pPickOffset.x,pPickOffset.y,pPickOffset.z);

        ! Activate collision recovery
        !CollRecOn;

        ! As the BP system cant calculate the robot configuration we have to set ConfL\Off to ignore these
        ! and then move in small increments to the gripping position
        ConfL\Off;
        ConfJ\Off;

        ! Allow TCP to deviate to get past sigular points (Axis 4 and 6 in line
        SingArea\Wrist;

        ! Disable corner path warning when picking
        !CornerPathWarning FALSE;

        !nBPPrevPickId:=nBP_PickId;

        ! Move towards picking position. Move 25% of the distance in each Move
        MoveJ UtlCalcTarget(rAboveBox,rAbovePickIn,0.25),v2000,z10,tTool\WObj:=wobjBox;
        MoveJ UtlCalcTarget(rAboveBox,rAbovePickIn,0.50),v1000,z10,tTool\WObj:=wobjBox;
        MoveJ UtlCalcTarget(rAboveBox,rAbovePickIn,0.75),v800,z10,tTool\WObj:=wobjBox;
        MoveJ UtlCalcTarget(rAboveBox,rAbovePickIn,1.00),v600,z10,tTool\WObj:=wobjBox;

        ! Move to actual picking position
        MoveL rPick,v300,fine,tTool\WObj:=wobjBox;
        
        ! TODO Grip product
        Stop;

        MoveL rAbovePickOut,v400,fine,tTool\WObj:=wobjBox;

        ! Move out to the position above the box
        MoveJ UtlCalcTarget(rAboveBox,rAbovePickOut,0.75),v600,z10,tTool\WObj:=wobjBox;
        MoveJ UtlCalcTarget(rAboveBox,rAbovePickOut,0.50),v1000,z10,tTool\WObj:=wobjBox;
        MoveJ UtlCalcTarget(rAboveBox,rAbovePickOut,0.25),v1000,z10,tTool\WObj:=wobjBox;

        ! Configurations can now be used again
        ConfL\On;
        ConfJ\On;
        
        ! Move to above box position with configurations on
        MoveJ rAboveBox,v2500,z200,tTool\WObj:=wobjBox;

        ! Do not tolerate singular points
        SingArea\Off;

        ! Enable corner path warning
        ! IF C_MOTSET.corner_path_warn_suppress=TRUE THEN
        !     CornerPathWarning TRUE;
        ! ENDIF
        !
        ! Deactivate collision recovery
        !CollRecOff;
        !
    ENDPROC
    
    FUNC robtarget UtlCalcTarget(robtarget rStart, robtarget rStop, num nT)
        VAR robtarget rRes;
        
        rRes.trans := rStart.trans + ((rStop.trans - rStart.trans) * nT);
        
        IF nT>=1.0 THEN
            rRes.rot := rStop.rot;
        ELSEIF nT<=0.0 THEN
            rRes.rot := rStart.rot;
        ELSE
            rRes.rot := Slerp(rStart.rot, rStop.rot, nT);
        ENDIF
        
        RETURN rRes;
    ENDFUNC
    
    ! Perform spherical linear interpolation between two quaternions
	! nT range [0, 1]
    FUNC orient Slerp(orient orientA, orient orientB, num nT)
        VAR orient oA;
        VAR num cosOmega;
        VAR num k0;
        VAR num k1;
        VAR num sinOmega;
        VAR num omega;
        VAR num oneOverSinOmega;
        VAR orient oRes;
    
        oA := orientA;
        cosOmega := orientA.q1*orientB.q1 + orientA.q2*orientB.q2 + orientA.q3*orientB.q3 + orientA.q4*orientB.q4;
        
        IF (cosOmega < 0.0) THEN
            oA.q1 := -oA.q1;
            oA.q2 := -oA.q2;
            oA.q3 := -oA.q3;
            oA.q4 := -oA.q4;
            cosOmega := -cosOmega;
        ENDIF
        
        IF (cosOmega > 0.9999) THEN
            k0 := 1.0 - nT;
            k1 := nT;
        ELSE
            sinOmega := Sqrt(1.0 - cosOmega* cosOmega);
            omega := DegToRad(ATan2(sinOmega, cosOmega));
            oneOverSinOmega := 1.0 / sinOmega;
            
            k0 := Sin(RadToDeg((1.0 - nT) * omega)) * oneOverSinOmega;
            k1 := Sin(RadToDeg(nT * omega * oneOverSinOmega));
        ENDIF
        
        oRes.q1 := oA.q1*k0 + orientB.q1*k1;
        oRes.q2 := oA.q2*k0 + orientB.q2*k1;
        oRes.q3 := oA.q3*k0 + orientB.q3*k1;
        oRes.q4 := oA.q4*k0 + orientB.q4*k1;
        RETURN oRes;
    ENDFUNC
    
    ! Convert degrees to radians
	FUNC num DegToRad(num Degrees)
		RETURN Degrees * (pi / 180.0);
	ENDFUNC
	
	! Convert radians to degrees
	FUNC num RadToDeg(num Radians)
		RETURN Radians * (180.0 / pi);
	ENDFUNC
    
    FUNC robtarget UtlRobtargetFrameConv(robtarget r, PERS wobjdata wFrom, PERS wobjdata wTo)
        VAR pose pIn;
        VAR pose pOut;
        VAR pose pWobj0;
        VAR robtarget rOut;
        
        rOut := r;
        pIn := [r.trans, r.rot];
        pWobj0 := PoseMult(PoseMult(wFrom.uframe, wFrom.oframe), pIn);
        pOut := PoseMult(PoseInv(PoseMult(wTo.uframe, wTo.oframe)), pWobj0);
        rOut.trans := pOut.trans;
        rOut.rot := pOut.rot;
        RETURN rOut;
    ENDFUNC
   
   
ENDMODULE
