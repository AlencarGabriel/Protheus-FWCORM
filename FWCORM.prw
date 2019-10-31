#INCLUDE "TOTVS.CH"

#DEFINE CLRF CHR(13)+CHR(10)
#DEFINE QT '"'


CLASS FWCORM FROM FWCORMStruct

	DATA cAlias  // tabela principal do banco de dados para instancia��o da classe
	DATA aLabels // apelidos amig�veis para referenciar tabelas do banco de dados
	DATA oData

	METHOD New( cAlias, cLabel ) CONSTRUCTOR
	METHOD Seek( cName, cSeek, nIndex )

ENDCLASS

METHOD New(cAlias, cLabel) CLASS FWCORM AS OBJECT //UNDEFINED

	Default cAlias := ""
	Default cLabel := ""

	If !Empty(cAlias)

		_Super:New(cAlias)

		::cAlias := cAlias
		::aLabels := {}

		// Layout de aLabels
		// ::aLabels := {;
		// 	{ "SC5" , "Pedidos" };
		//	{ "SC6" , "Itens"   } };
		If !Empty( cLabel )
			aAdd( ::aLabels, { cAlias, cLabel } )
		EndIf
	Else
		Conout( '__FWCORM():NEW() SAYS: ARGUMENTO CALIAS NAO INFORMADO' )
	EndIf

Return SELF


/*/{Protheus.doc} FWCORMStruct:Seek()
Localiza um registro no banco de dados e popula o objeto oData.
@author Giovani M. Soares.
@since 28/10/2019
@version 1.0
@return lRet, .T. representa sucesso na opera��o e .F. indica falhas.
@param cName, characters, Nome ou apelido da tabela do banco de dados.
@param nIndex, numeric, �ndice para busca, valor padr�o 1.
@param cSeek, characters, Chave de busca conforme �ndice informado.
@obs Obs.: O apelido (nome amig�vel) pode ser utilizado no argumento cName do m�todo.
@type Method
/*/
METHOD Seek( cName, cSeek, nIndex ) CLASS FWCORM AS LOGICAL

	Local nPos     := 0

	Local aData    := {}
	Local aX3Names := {}

	Local cAlias   := ""

	Local oData    := JsonObject():New()
	Local oJsValue := JsonObject():New()

	Local bError   := {||}

	Local lRet     := .F.

	Default cName  := ""
	Default cSeek  := ""
	Default nIndex := 1

	// Necess�rio tratamento por meio do BEGIN SEQUENCE
	// pois nem sempre o objeto/array _REMNANT existir� dentro de oXML
	bError := ErrorBlock( {|oError| GetError(oError)})

	BEGIN SEQUENCE

		// --------------------------------------------------
		// Define qual tabela ser� utilizada para realiza��o
		// do seek no banco de dados.
		// --
		// Obs.: caso n�o econtre, tenta localizar a tabela
		// pelo apelido (nome amig�vel).
		// --------------------------------------------------
		If cName == ::cAlias
			cAlias := cName
		Else
			If Len( ::aLabels ) > 0
				nPos := aScan( self:aLabels, { |x| Upper(x[2]) == Upper(cName) } )
				If nPos > 0
					cAlias := ::aLabels[nPos,1]
				EndIf
			EndIf
		EndIf

		// --------------------------------------------------
		// Se cAlias existir busca pelo registro conforme
		// argumentos nIndex e cSeek.
		// --------------------------------------------------
		If !Empty(cAlias)

			DbSelectArea(cAlias) ; (cAlias)->(DbSetOrder(nIndex))

			If (cAlias)->(MsSeek(cSeek))

				aX3Names := _Super:Getnames()

				For nX := 1 To Len(aX3Names)
					// Garante que apenas a tabela apontada por cName ser� processada
					If aX3Names[nX,1] != cAlias
						Loop
					EndIf
					// Gera c�digo para macro-execu��o
					// Ex.: Self:oStruct:SC5:SX3:C5_FILIAL:X3_CONTEXT
					cX3_CONTEXT := "Self:oStruct:" + aX3Names[nX,1] +":SX3:"+ aX3Names[nX,2] + ":X3_CONTEXT"
					// Conforme macro-execu��o, avalia se o campo � Real ou Virtual
					// Caso seja, virtual, � ignorado
					If ( &(cX3_CONTEXT) != "V" )
						oJsValue[aX3Names[nX,2]] := (cAlias)->(&(aX3Names[nX,2]))
					EndIf
				Next nX

				oData[cName] := { oJsValue }

				cData := oData:toJson()

				FreeObj(oData)

				FwJsonDeserialize(cData,@oData)

				::oData := oData

				lRet := .T.

			Else
				Conout( '__FWCORM():SEEK() SAYS: NAO FOI POSSIVEL LOCALIZAR NENHUM REGISTRO PELA CHAVE E INDICE INFORMADOS -' +;
				' CHAVE: ' + QT + Upper(cSeek) + QT +;
				' INDICE: ' + cValToChar(nIndex) )
			EndIf
		Else
			Conout( '__FWCORM():SEEK() SAYS: O ARGUMENTO CNAME INFORMADO NAO E VALIDO - ' + QT + Upper(cName) + QT )
		EndIf

	END SEQUENCE

	ErrorBlock(bError) // restaura tratamento de erro padr�o do sistema

Return lRet

/*
Static Function GetError(oError)
	Break
Return()
*/