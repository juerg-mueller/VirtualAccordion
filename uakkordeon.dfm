object Akkordeon: TAkkordeon
  Left = 519
  Top = 407
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
    Top = 17
    Width = 74
    Height = 15
    Caption = 'Transponieren'
    Color = clBtnFace
    ParentColor = False
  end
  object Label2: TLabel
    Left = 320
    Top = 15
    Width = 112
    Height = 15
    Caption = 'Notenwerte anzeigen'
    Color = clBtnFace
    ParentColor = False
  end
  object Label3: TLabel
    Left = 320
    Top = 46
    Width = 107
    Height = 15
    Caption = 'vertikale Darstellung'
    Color = clBtnFace
    ParentColor = False
  end
  object Label4: TLabel
    Left = 32
    Top = 120
    Width = 58
    Height = 15
    Caption = 'Instrument'
    Color = clBtnFace
    ParentColor = False
  end
  object cbxTranspose: TComboBox
    Left = 184
    Top = 11
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
      Height = 23
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
      Height = 23
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
      Caption = 'MIDI OUT zur'#252'cksetzen'
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
  object cbxAnzeigen: TCheckBox
    Left = 464
    Top = 15
    Width = 21
    Height = 21
    Checked = True
    State = cbChecked
    TabOrder = 2
    OnClick = cbxAnzeigenClick
  end
  object cbxVertikal: TCheckBox
    Left = 464
    Top = 42
    Width = 28
    Height = 21
    TabOrder = 3
    OnClick = cbxVertikalClick
  end
  object cbxInstruments: TComboBox
    Left = 122
    Top = 112
    Width = 638
    Height = 23
    ItemIndex = 0
    TabOrder = 4
    Text = 'default'
    OnChange = cbxInstrumentsChange
    Items.Strings = (
      'default')
  end
end
