object Ampel: TAmpel
  Left = 508
  Height = 368
  Top = 412
  Width = 1198
  VertScrollBar.Smooth = True
  Caption = 'Ampel'
  ClientHeight = 368
  ClientWidth = 1198
  Font.Height = -19
  Font.Name = 'Sans'
  OnCreate = FormCreate
  OnMouseDown = FormMouseDown
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  OnPaint = FormPaint
  Visible = True
  object cbxScrollBar: TCheckBox
    Left = 88
    Height = 21
    Top = 6
    Width = 21
    Alignment = taLeftJustify
    TabOrder = 0
  end
  object Label1: TLabel
    Left = 17
    Height = 18
    Top = 8
    Width = 55
    Caption = 'Scroll Bar'
    Font.Height = -13
    Font.Name = 'Sans'
    ParentColor = False
    ParentFont = False
  end
end
