#define MAX 4
byte clock = 0;
byte maxPeriod;
chan queue = [MAX] of { byte };

proctype T(byte ID; byte period; byte exec) {
    byte next = 0;
    byte deadline = period;
    byte current = 0;

    end:
        do
        :: atomic {
            (clock >= next) && (clock < deadline) && (clock < maxPeriod) && !(queue ?? [eval(ID)]) ->
                queue !! ID
            }

        :: atomic {
            (clock >= next) && (clock < deadline) && (queue ? [eval(ID)]) ->
                current++;
                clock++;

                if
                :: current == exec ->
                    queue ? eval(ID);
                    current = 0;
                    next = next + period
                :: else
                fi
            }

        :: atomic {
            (clock >= deadline) ->
                assert (!(queue ?? [eval(ID)]));
                deadline = deadline + period
            }
        od
}

proctype Idle() {
    end:
        do
        :: atomic {
            (clock < maxPeriod) && timeout ->
                clock++
            }
        od
}

init {
    atomic {

        maxPeriod = 10;
        queue ! 0;
        queue ! 1;

        run T(0, 6, 3);
	    run T(1, 10, 5);

        run Idle();

        
    }
}
