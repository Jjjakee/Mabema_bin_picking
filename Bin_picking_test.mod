MODULE Module1


    PROC main()
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



ENDMODULE
