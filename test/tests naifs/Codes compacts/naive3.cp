*19*

func #ASerachFood() {

    if (
        randint(3) is 0
    )
    then {
        turn(1);
        goto #B18;
        #A18:
    }
    else {
        do {
            turn(5);
            goto #F19;
            #A19:
        }
        if (
            randint(2) is 0
        )
    } *choisis une direction aléatoirement*

    if (
        food is left
    )
    then {
        turn(5);
        goto #F0;
        #A0:
    }
    else {
        do {
            turn(1);
            goto #B1;
            #A1:
        }
        if (
            food is right
        )
   } *va là où il y a de la nouriture, s il y en a*

    if (
        bit(!00) is here
    )
    then {
        nop;
    }
    else {
        if (
        bit(!01) is here
        )
        then {
            nop;
        }
        else {
            if (
                bit(!02) is here
            )
            then {
                nop;
            }
            else {   
                if (
                    bit(!03) is here
                )
                then {
                    nop;
                }
                else {   
                    if (
                        bit(!04) is here
                    )
                    then {
                        nop;
                    }
                    else {   
                        if (
                            bit(!05) is here
                        )
                        then {
                            nop;
                        }
                        else {   
                            mark(!01);
                        }
                    }
                }
            }
        }
    } *marque sa direction si le chemin n est pas déjà marqué*


    if (
        friendWithFood is ahead
    )
    then {
        turn(1);
        goto #B7;
        #A7:
        move(1);
        turn(5);
        goto #F8;
        #A8:
        move(1);
        turn(1);
        goto #B9;
        #A9;
    } *contourne un allié si il y en a un sur le passage*
    else {
        if (
            rock is ahead
        )
        then {
            turn(3);
            goto #D10;
            #A10:
        }
        else {
            move(1);
        }
    } *fais demi-tour si il y a un rocher, avance sinon*

    pickup(#ASerachFood); *si pas de nouriture, refais une recherche*
    turn(3); *sinon, fais demi-tour et rammene la nouriture*
    goto #D2;
    #A2:
    call #ABackFood; *essaye de prendre de la nouriture*

}
func #ABackFood{
    do {
        drop();
        turn(3);
        goto #D5;
        #A5:
        call #ASerachFood;
    }
    if (
        home is here
    )

    if (
        bit(!00) is here
    )
    then {
        nop;
    }
    else {
        if (
            bit(!01) is here
        )
        then {
            turn(1);
            goto #B13;
            A13:
        }
        else {
            if (
                bit(!02) is here
            )
            then {
                turn(2);
                goto #C14;
                A14:
            }
            else {
                if (
                    bit(!03) is here
                )
                then {
                    turn(3);
                    goto #D15;
                    A15:
                }
                else {
                    if (
                        bit(!04) is here
                    )
                    then {
                        turn(4);
                        goto #E16;
                        A16:
                    }
                    else {
                        if (
                            bit(!05) is here
                        )
                        then {
                            turn(5);
                            goto #F17;
                            A17:
                        }
                        else {
                    
                        }
                    }
                }
            }
        }
    } *suivit du chemin de retour*
    *le numéro du bit à tester dépend de l orientation de la fourmi*
    move(1);
}