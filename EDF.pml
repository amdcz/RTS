#define MAX 4
bool interrupt = false;
byte clock = 0;
byte maxPeriod;
chan queue = [MAX] of { byte };
chan stop = [MAX] of { byte };
chan proc_id = [MAX] of { byte };
chan com = [0] of { byte };

proctype T(byte now, byte period; byte exec) provided (!interrupt){
    byte ID = _pid; 
    byte next = 0;
    byte deadline = period;
    byte current = 0;
    proc_id !! now;
    stop !! deadline;

    end:
        do
        :: atomic {
            (clock >= next) && (clock < deadline) && (clock < maxPeriod) && !(queue ?? [eval(ID)]) ->
                queue !! ID;
            }

        :: atomic {
            (clock >= next) && (clock < deadline) && (queue ? [eval(ID)]) ->
                current++;
                clock++;

                if
                :: current == exec ->
                    queue ? eval(ID);
                    current = 0;
                    next = next + period;
                    
                :: else
                fi
            }

        :: atomic {
            (clock >= deadline) ->
                assert (!(queue ?? [eval(ID)]));
                deadline = deadline + period;
                stop !! deadline;
                run Interrupt();
                com ? ID;

            }
        od
}

proctype Idle() provided (!interrupt){
    end:
        do
        :: atomic {
            (clock < maxPeriod) && timeout ->
                clock++;
            }
        od
}

proctype Interrupt() {
    interrupt = true;

    int cnt = 0;
    byte temp;
    byte maxdeadline = 0;

    do
    :: atomic{
        stop ? temp ->
            cnt++;

            if
            :: (temp > maxdeadline) -> 
                    maxdeadline = temp
            :: else 
            fi
        }

    :: atomic{
        else
            interrupt = false
            break
        }
    od

    com ! cnt;
}

init {

    atomic {

        maxPeriod = 33;

        run T(1, 10, 5);

        run Idle();

        run T(0, 6, 3);

    }

    assert(clock < maxPeriod);
}
