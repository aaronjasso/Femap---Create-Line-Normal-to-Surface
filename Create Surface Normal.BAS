Sub Main
	'====================================================
	'Create a line normal to a plane at a selected point.
	'
	'Copyright (c) 2020, Aaron Jasso
    '
    'This program is free software: you can redistribute it and/or modify
    'it under the terms of the GNU General Public License as published by
    'the Free Software Foundation, either version 3 of the License, or
    '(at your option) any later version.
    '
    'This program is distributed in the hope that it will be useful,
    'but WITHOUT ANY WARRANTY; without even the implied warranty of
    'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    'GNU General Public License for more details.
    '
    'You should have received a copy of the GNU General Public License
    'along with this program.  If not, see <https://www.gnu.org/licenses/>.
    '
    'New in Version 2.0:
	'-Added multi-point selection option to create normals at more than one point
	'
	'Written by AMJ, 4.28.2020
	'====================================================
    Dim App as femap.model
    Set App = feFemap()

    Dim rc As zReturnCode

	'====================================================
	'Enable surface normals
	'====================================================
	Dim iterView As femap.View
	Set iterView = App.feView

	Dim viewID As Long

	rc = App.feAppGetActiveView(viewID)

	iterView.Get(viewID)
	iterView.ColorMode(FVI_CURVE_ACCURACY) = 3
	iterView.Put(viewID)

	App.feViewRegenerate(viewID)

	'====================================================
	'Get point And surface from user
	'====================================================
    Dim pointSet As femap.Set
    Set pointSet = App.feSet

    Dim iterPoint As femap.Point
    Set iterPoint = App.fePoint

    Dim surfSet As femap.Set
    Set surfSet = App.feSet

    Dim iterSurf As femap.Surface
    Set iterSurf = App.feSurface

    Dim surfID As Long
    Dim pointID As Long

    Dim reverse As Boolean

    reverse = False

	Begin Dialog UserDialog 480,224,"Create Line Normal to Surface",.DialogFunc ' %GRID:10,7,1,1
		GroupBox 10,0,460,105,"Instructions",.GroupBox1
		OKButton 40,182,130,35
		PushButton 180,182,130,35,"Reverse",.reverse
		CancelButton 320,182,130,35
		Text 30,21,430,42,"Surface arrows have been enabled. Clicking OK will create a normal vector on the same side as the arrows, clicking Reverse will create it on the opposite side.",.Text1
		Text 30,70,430,28,"After you choose, you'll be prompted to select the surface and a point on that surface.",.Text2
		CheckBox 280,56,180,14,"Reverse",.oppo
		GroupBox 10,105,460,70,"Input",.input
		TextBox 200,147,90,14,.length
		Text 30,147,160,14,"Create normal of length:",.Text3
		CheckBox 30,126,180,14,"View Surface Directions",.viewSurfDir
	End Dialog
	Dim dlg As UserDialog
	dlg.length = "1"
	Dialog dlg

	'Get surface
	rc = surfSet.SelectID(FT_SURFACE,"Select Surface To Create Normal",surfID)
	If rc = FE_CANCEL Then
		iterView.ColorMode(FVI_CURVE_ACCURACY) = 0
		iterView.Put(viewID)
		App.feViewRegenerate(viewID)
		Exit All
	End If
	iterSurf.Get(surfID)

	'Get points
	lblGetPoint:
	rc = pointSet.Select(FT_POINT,True,"Select point(s) for normal origins")
	'rc = pointSet.SelectID(FT_POINT,"Select point on surface for normal",pointID)
	If rc = FE_CANCEL Then
		iterView.ColorMode(FVI_CURVE_ACCURACY) = 0
		iterView.Put(viewID)
		App.feViewRegenerate(viewID)
		Exit All
	End If
	'iterPoint.Get(pointID)

	'====================================================
	'Check that point is on surface. If not, give option to attempt projection onto
	'surface. If projection is successful, create projected point in active layer and
	'make it the new iterPoint object in this script.
	'====================================================

	Dim layerID As Long	'This is done here in case it's needed for a projection.
	'it will also be used to create the normal curve later.
	layerID = App.Info_ActiveID(FT_LAYER)

	Dim badPointSet As femap.Set
	Set badPointSet = App.feSet

	Dim badPoints As Long
	badPoints = 0

	pointSet.Reset

	While pointSet.Next
		iterPoint.Get(pointSet.CurrentID)
		rc = iterSurf.InsideXYZ(iterPoint.xyz)
		If rc = FE_FAIL Then
			badPoints = badPoints + 1
			badPointSet.Add(iterPoint.ID)
		End If
	Wend

	If badPoints <>0 Then
		rc = MsgBox(badPoints & " of the selected point(s) do not lie on the surface. Would you like to attempt to project them onto the surface?" & vbNewLine & vbNewLine & "(Click No to skip all points not on the surface, click Cancel to re-select points.",vbYesNoCancel,"Problem with Selected Points")
	End If

	Select Case rc
	Case 6	'Yes
		Dim projectedXYZ As Variant

		Dim brokenPointSet As femap.Set
		Set brokenPointSet = App.feSet

		badPointSet.Reset
		While badPointSet.Next
			iterPoint.Get(badPointSet.CurrentID)
			rc = iterSurf.ProjectOnto(iterPoint.xyz,.00001,projectXYZ)
			If rc = FE_FAIL Then
				brokenPointSet.Add(iterPoint.ID)
				pointSet.Remove(iterPoint.ID)
			Else
				pointID = App.Info_NextID(FT_POINT)
				With iterPoint
					.xyz = projectXYZ
					.layer = layerID
				End With
				iterPoint.Put(pointID)
				App.feAppMessage(FCM_NORMAL,"Created Point " & iterPoint.ID)
				'App.feAppMessage(FCM_NORMAL,"Coords: " & iterPoint.x & ", " & iterPoint.y & ", " & iterPoint.z)
				pointSet.Add(pointID)
				pointSet.Remove(badPointSet.CurrentID)
			End If
		Wend

		If brokenPointSet.Count > 0 Then
			MsgBox(brokenPointSet.Count & " point(s) were unable to be projected onto selected surface and have been removed from the selection.", vbInformation,"Projection Results")
		End If

	Case 7	'No (Skip non-surface points)
		pointSet.RemoveSet(badPointSet.ID)
	Case 2	'Cancel (re-select points)
		GoTo lblGetPoint
	End Select


	'====================================================
	'Create normal vector(s)
	'====================================================
	Dim normPoint As femap.Point
	Set normPoint = App.fePoint

	Dim normXYZ As Variant
	Dim sign As Long

	Dim iterCurve As femap.Curve
	Set iterCurve = App.feCurve

	Dim curveID As Long

	If dlg.oppo = 0 Then
		sign = 1
	Else
		sign = -1
	End If

	pointSet.Reset
	While pointSet.Next
		iterPoint.Get(pointSet.CurrentID)
		iterSurf.NormalAtXYZ(1,iterPoint.xyz,normXYZ)

		normXYZ(0) = iterPoint.xyz(0) + (sign * normXYZ(0) * Val(dlg.length))
		normXYZ(1) = iterPoint.xyz(1) + (sign * normXYZ(1) * Val(dlg.length))
		normXYZ(2) = iterPoint.xyz(2) + (sign * normXYZ(2) * Val(dlg.length))

		'Create a point at the far end of the normal vector
		With normPoint
			.ID = App.Info_NextID(FT_POINT)
			.layer = layerID
			.xyz = normXYZ
		End With

		normPoint.Put(0)
		App.feAppMessage(FCM_NORMAL,"Created Point " & normPoint.ID)

		'Create line between points
		curveID = App.Info_NextID(FT_CURVE)
		With iterCurve
			.type = FCU_LINE
			.StdPoint(0) = iterPoint.ID
			.StdPoint(1) = normPoint.ID
			.layer = layerID
		End With

		iterCurve.Put(curveID)
		App.feAppMessage(FCM_NORMAL,"Created Curve " & iterCurve.ID)
	Wend


	'====================================================
	'Disable surface normals
	'====================================================
	iterView.Get(viewID)
	iterView.ColorMode(FVI_CURVE_ACCURACY) = 0
	iterView.Put(viewID)

	App.feViewRegenerate(viewID)
    
End Sub

Rem See DialogFunc help topic for more information.
Private Function DialogFunc(DlgItem$, Action%, SuppValue?) As Boolean
	Select Case Action%
	Case 1 ' Dialog box initialization
		'hide the reverse checkbox
		DlgVisible "oppo", False
		'Check surface normal vis box
		DlgValue "viewSurfDir", 1

	Case 2 ' Value changing or button pressed
		'MsgBox("DlgItem: " & DlgItem, vbOkOnly,"Info")
		Dim app2 As femap.model
		Set app2 = feFemap()
		Dim viewID As Long
		Dim iterView As femap.View
		Set iterView = app2.feView
		app2.feAppGetActiveView(viewID)
		iterView.Get(viewID)

		Select Case DlgItem
		Case "Cancel"	'hande cancel button
			iterView.ColorMode(FVI_CURVE_ACCURACY) = 0
			iterView.Put(viewID)
			app2.feViewRegenerate(viewID)
			Exit All
		Case "reverse"
			DlgValue "oppo",1
		Case "viewSurfDir"
			If SuppValue? = 0 Then
				iterView.ColorMode(FVI_CURVE_ACCURACY) = 0
			ElseIf SuppValue? = 1 Then
				iterView.ColorMode(FVI_CURVE_ACCURACY) = 3
			End If
			iterView.Put(viewID)
			app2.feViewRegenerate(viewID)
		End Select
	Case 3 ' TextBox or ComboBox text changed
		
	Case 4 ' Focus changed
		
	Case 5 ' Idle
		Rem Wait .1 : DialogFunc = True ' Continue getting idle actions
		Wait .1

	Case 6 ' Function key
	End Select
End Function
