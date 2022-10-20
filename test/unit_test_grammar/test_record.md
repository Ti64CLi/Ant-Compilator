## Voici La grammaire avec ce formalisme :
%% fichier_de_test_pour_cette_ligne.ant %%
après chaque ligne testé, qui indique dans quels fichiers des tests sont faits pour cette ligne

type program =
	| PreprocessorProgram		<preprocessor> <program?>
	| ControlProgram			<control> <program?>
	| ExpressionProgram			<expression>; <program?>

type preprocessor =
	| Include					include <ident>
	%% test_Include.ant %%

	| Define					define <ident> as <program>
	%% test_1.ant %%

	| Org						.org <ident>
	%% test_Org.ant %%

type control =
	| Label						<ident>:
	%% test_Label.ant %%

	| IfThenElse				if(<bool>) then {<program>} else {<program>}
	%% test_IfThenElse.ant %%

	| Func						func <ident>(<ident*,>) {<program>}
	%% test_0.ant, test_1.ant %%

	| While						while(<bool>) {<program>}
	%% test_While.ant %%

	| Repeat					repeat(<bool>) {<program>}
	%% test_Repeat.ant %%

	| Case						case <bool>: <program>
	%% test_0.ant %%

	| Switch					test(<bool>) in {<program>}
	%% test_0.ant %%
	

type expression =
	| Num						<int>
	%% test_Num.ant %%

	| Args						args[<int>]
	%% test_.ant %%

	| Move						move(<int>)
	%% test_0.ant %%

	| Turn						turn(<int>)
	%% test_.ant %%

	| PickUp					pickup(<ident>)
	%% test_.ant %%

	| Drop						drop()
	%% test_.ant %%

	| Goto						goto <ident>
	%% test_.ant %%

	| Mark 						mark(<int>)
	%% test_.ant %%

	| Unmark					unmark(<int>)
	%% test_.ant %%

	| Call						call <ident>
	%% test_0.ant %%

	| IfThen					do {<program>} if(<bool>)
	%% test_.ant %%

	| Nop						nop
	%% test_.ant %%

	| Return					return
	%% test_.ant %%

	| Break						break
	%% test_.ant %%

type bool =
	| Value						<value>
	%% test_.ant %%

	| Category					<category>
	%% test_.ant %%

	| Dir						<direction>
	%% test_.ant %%

	| Or						or(<bool>, <bool>)
	%% test_.ant %%

	| And						and(<bool>, <bool>)
	%% test_.ant %%

	| Equal 					eq(<bool>, <bool>)
	%% test_.ant %%

	| Not						not(<bool>)
	%% test_.ant %%

	| NotEqual					neq(<bool>, <bool>)
	%% test_.ant %%
	
	| Is						is(<category>, <direction>)
	%% test_.ant %%

type value =
	| Var						<ident>
	%% test_.ant %%

	| Int						<int>
	%% test_.ant %%


type direction =
	| Ahead						ahead
	%% test_.ant %%

	| Left						left
	%% test_.ant %%

	| Right						right
	%% test_.ant %%

	| Here						here
	%% test_.ant %%


type category =
	| Friend					friend
	%% test_.ant %%

	| Foe						foe
	%% test_.ant %%

	| FriendWithFood			friendWithFood
	%% test_.ant %%

	| FoeWithFood				foeWithFood
	%% test_.ant %%

	| Food						food
	%% test_.ant %%

	| Rock						rock
	%% test_.ant %%

	| Marker					bit(<value>)
	%% test_.ant %%

	| FoeMarker					foeMarker
	%% test_.ant %%

	| Home						home
	%% test_.ant %%

	| FoeHome					foeHome
	%% test_.ant %%

	| RandInt					randint(<value>)
	%% test_.ant %%

