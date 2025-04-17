object Akkordeon: TAkkordeon
  Left = 1237
  Top = 472
  HorzScrollBar.Smooth = True
  Caption = 'Akkordeon'
  ClientHeight = 392
  ClientWidth = 777
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClick = FormClick
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object Label1: TLabel
    Left = 32
    Top = 14
    Width = 74
    Height = 15
    Caption = 'Transponieren'
    Color = clBtnFace
    ParentColor = False
  end
  object Label2: TLabel
    Left = 32
    Top = 54
    Width = 62
    Height = 15
    Caption = 'Notenwerte'
    Color = clBtnFace
    ParentColor = False
  end
  object Label4: TLabel
    Left = 32
    Top = 129
    Width = 58
    Height = 15
    Caption = 'Instrument'
    Color = clBtnFace
    ParentColor = False
  end
  object Label5: TLabel
    Left = 32
    Top = 92
    Width = 40
    Height = 15
    Caption = 'Ansicht'
    Color = clBtnFace
    ParentColor = False
  end
  object cbxTranspose: TComboBox
    Left = 136
    Top = 9
    Width = 68
    Height = 23
    ItemIndex = 11
    TabOrder = 0
    Text = '0'
    OnChange = cbxInstrumentsChange
    Items.Strings = (
      '-11'
      '-10'
      '-9'
      '-8'
      '-7'
      '-6'
      '-5'
      '-4'
      '-3'
      '-2'
      '-1'
      '0'
      '1'
      '2'
      '3'
      '4'
      '5'
      '6'
      '7'
      '8'
      '9'
      '10'
      '11')
  end
  object gbMidi: TGroupBox
    Left = 0
    Top = 168
    Width = 777
    Height = 224
    Align = alBottom
    Caption = 'MIDI I/O'
    TabOrder = 1
    DesignSize = (
      777
      224)
    object lblKeyboard: TLabel
      Left = 24
      Top = 26
      Width = 40
      Height = 15
      Caption = 'MIDI IN'
      Color = clBtnFace
      ParentColor = False
    end
    object Label17: TLabel
      Left = 24
      Top = 90
      Width = 51
      Height = 15
      Caption = 'MIDI OUT'
      Color = clBtnFace
      ParentColor = False
    end
    object cbxMidiOut: TComboBox
      Left = 122
      Top = 84
      Width = 638
      Height = 35
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      OnChange = cbxMidiOutChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object cbxMidiInput: TComboBox
      Left = 122
      Top = 16
      Width = 638
      Height = 35
      Style = csDropDownList
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = cbxMidiInputChange
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object btnReset: TButton
      Left = 122
      Top = 128
      Width = 638
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Caption = 'MIDI OUT zur'#195#188'cksetzen'
      TabOrder = 3
      OnClick = btnResetClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
    object btnResetMidi: TButton
      Left = 122
      Top = 160
      Width = 638
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Caption = 'MIDI Konfiguration neu laden'
      TabOrder = 2
      OnClick = btnResetMidiClick
      OnKeyDown = cbTransInstrumentKeyDown
      OnKeyPress = cbTransInstrumentKeyPress
      OnKeyUp = cbTransInstrumentKeyUp
    end
  end
  object cbxInstruments: TComboBox
    Left = 122
    Top = 121
    Width = 638
    Height = 31
    TabOrder = 2
    Text = 'C-Griff Europe'
  end
  object cbxAnsicht: TComboBox
    Left = 122
    Top = 84
    Width = 636
    Height = 23
    ItemIndex = 0
    TabOrder = 3
    Text = 'Horizontal'
    OnChange = cbxAnsichtChange
    Items.Strings = (
      'Horizontal'
      'Vertikal Spielersicht'
      'Vertikal Zuschauersicht')
  end
  object cbxNotenansicht: TComboBox
    Left = 122
    Top = 47
    Width = 636
    Height = 23
    ItemIndex = 1
    TabOrder = 4
    Text = 'mit Nummer'
    OnChange = cbxAnsichtChange
    Items.Strings = (
      ''
      'mit Nummer'
      'ohne Nummer'
      'mit Apostoph')
  end
end
