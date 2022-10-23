## Voici La grammaire avec ce formalisme :

%% fichier_de_test_pour_cette_ligne.ant %%
après chaque ligne testé, qui indique dans quels fichiers des tests sont faits pour cette ligne

``` python
type program =
| PreprocessorProgram <preprocessor> <program?
| ControlProgram <control> <program?>
| ExpressionProgram <expression>; <program?>


type preprocessor =
	| Include include <ident>
	%% test_Include.ant %%

    | Define				define <ident> as <program>
    DONE %% 2_test_define.ant %%

    | Org					.org <ident>
    %% test_Org.ant %%

type control =
	| Label <ident>:
	DONE %% 0_test_label.ant %%

    | IfThenElse			if(<bool>) then {<program>} else {<program>}
    DONE %% 15_test_ifthenelse.ant %%

    | Func					func <ident>(<ident*,>) {<program>}
    DONE %% 3_test_func.ant %%

    | While					while(<bool>) {<program>}
    DONE %% 16_test_while.ant %%

    | Repeat				repeat(<bool>) {<program>}
    DONE %% 6_test_repeat.ant %%

    | Case					case <bool>: <program>
    %%  %%

    | Switch				test(<bool>) in {<program>}
    %%  %%

type expression =
	| Num <int>
	DONE %% 6_test_repeat.ant %%

    | Args					args[<int>]
    %%  %%

    | Move					move(<int>)
    DONE %% 1_test_move.ant %%

    | Turn					turn(<int>)
    DONE %% 7_test_turn.ant %%

    | PickUp				pickup(<ident>)
    DONE %% 8_test_pickup.ant %%

    | Drop					drop()
    DONE %% 9_test_drop.ant %%

    | Goto					goto <ident>
    DONE %% 4_test_goto.ant %%

    | Mark 					mark(<int>)
    DONE %% 11_test_mark.ant %%

    | Unmark				unmark(<int>)
    DONE %% 12_test_unmark.ant %%

    | Call					call <ident>
    DONE %% 10_test_call.ant %%

    | IfThen				do {<program>} if(<bool>)
    DONE %% 14_test_is_if.ant %%

    | Nop					nop
    DONE %% 13_test_nop.ant %%

    | Return				return
    %% test_.ant %%

    | Break					break
    %% test_.ant %%

type bool =
	| Value <value>
	DONE %% 2_test_define.ant %%

    | Category				<category>
    DONE %% 14_test_is_if.ant %%

    | Dir					<direction>
    DONE %% 14_test_is_if.ant %%

    | Or					or(<bool>, <bool>)
    DONE %% 16_test_while.ant %%

    | And					and(<bool>, <bool>)
    %% test_.ant %%

    | Equal 				eq(<bool>, <bool>)
    %% test_.ant %%

    | Not					not(<bool>)
    %% test_.ant %%

    | NotEqual				neq(<bool>, <bool>)
    %% test_.ant %%

    | Is					is(<category>, <direction>)
    DONE %% 14_test_is_if.ant %%

type value =
	| Var 			<ident>
	DONE %% 0_test_label.ant %%

    | Int			<int>
    DONE %% 2_test_define.ant %%

type direction =
	| Ahead 				ahead
	DONE %% 15_test_ifthenelse.ant %%

    | Left					left
    DONE %% 16_test_while.ant %%

    | Right					right
    DONE %% 16_test_while.ant %%

    | Here					here
    DONE %% 14_test_is_if.ant %%

type category =
	| Friend 				friend
	DONE %% 17_test_switch_case.ant %%

    | Foe					foe
    DONE %% 17_test_switch_case.ant %%

    | FriendWithFood		friendWithFood
    DONE %% 17_test_switch_case.ant %%

    | FoeWithFood			foeWithFood
    DONE %% 17_test_switch_case.ant %%

    | Food					food
    DONE %% 14_test_is_if.ant %%

    | Rock					rock
    DONE %% 15_test_ifthenelse.ant %%

    | Marker				bit(<value>)
    DONE %% 16_test_while.ant %%

    | FoeMarker				foeMarker
    %% test_.ant %%

    | Home					home
    %% test_.ant %%

    | FoeHome				foeHome
    %% test_.ant %%

    | RandInt				randint(<value>)
    %% test_.ant %%
```
