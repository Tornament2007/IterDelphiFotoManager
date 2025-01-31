unit FVInfo;
{
      ������ ��� ��������� ���������� � ������ ����������� ������
         OS Windows *.exe � *.dll (�����, ��������� ������).

      ����������: 2002, Ivan V. Klimov, ivklimov@mail.ru.
}

////////////////////////////////////////////////////////////////////////////////
interface

uses Windows, SysUtils;

type // ��� - ������ ��������� ��� ����� ���������� � ������ ����� (MSDN 6.0)
  TFviTags = (
    fviComments,
    fviCompanyName,
    fviFileDescription,
    fviFileVersion,
    fviInternalName,
    fviLegalCopyright,
    fviLegalTrademarks,
    fviOriginalFilename,
    fviPrivateBuild,
    fviProductName,
    fviProductVersion,
    fviSpecialBuild
  );

const // ����� ����� (�����) ��-���������:
  cFviFieldsDef : array[TFviTags] of String = (
    'Comments',
    'CompanyName',
    'FileDescription',
    'FileVersion',
    'InternalName',
    'LegalCopyright',
    'LegalTrademarks',
    'OriginalFilename',
    'PrivateBuild',
    'ProductName',
    'ProductVersion',
    'SpecialBuild'
  );

const // ����� ����� (�����) ��-������:
  cFviFieldsRus : array[TFviTags] of String = (
    '�����������',
    '�������������',
    '��������',
    '������ �����',
    '���������� ���',
    '��������� �����',
    '�������� �����',
    '�������� ��� �����',
    '��������� ������',
    '�������� ��������',
    '������ ��������',
    '������ ������'
  );

const
  RusLangID = $0419;

type
  TFileVersionInfoRecord = record
    LangID:     Word;  // Windows language identifier
    LangCP:     Word;  // Code page for the language
    LangName:   array[0..255] of Char;  // ������������ Windows ��� �����
    FieldDef:   array[TFviTags] of String; // ��� ��������� ��-���������
    FieldRus:   array[TFviTags] of String; // ��� ��������� ��-������
    Value:      array[TFviTags] of String; // �������� ���������
    FileVer:    String; // �����-����������� �������� ������ �����
    ProductVer: String; // �����-����������� �������� ������ ��������
    BuildType:  String; // �����-����������� - ��� ������
    FileType:   String; // �����-����������� - ��� ��������
  end;

procedure
 GetFileVersionInfoRecord(
  const FileName: String;
  out InfoRecord: TFileVersionInfoRecord;
  out FieldsCount: Integer
);

var
  AppFileInfo: TFileVersionInfoRecord;
  AppInfoFound: Boolean;

////////////////////////////////////////////////////////////////////////////////
implementation

procedure
 GetFileVersionInfoRecord(
  const FileName: String;
  out InfoRecord: TFileVersionInfoRecord;
  out FieldsCount: Integer
);
type
  TLangRec = array[0..1] of Word;
var
  InfoSize, zero: Cardinal;
  pbuff: Pointer;
  pk: Pointer;
  nk: Cardinal;
  pffi: ^VS_FIXEDFILEINFO;
  lang_hex_str: String;
  i: TFviTags;
begin
  FieldsCount := 0;
  pbuff := Nil;
  InfoSize := GetFileVersionInfoSize(PChar(FileName),zero);
  if InfoSize<>0 then
  try
    GetMem(pbuff,InfoSize);
    if GetFileVersionInfo(PChar(FileName),0,InfoSize,pbuff) then
    begin
      // root information - �����-����������� ����������:
      if VerQueryValue(pbuff,'\',Pointer(pffi),nk) then
      with InfoRecord do begin
        // ���� - �����������:
        LangID := 0;
        INC(FieldsCount);
        LangCP := 0;
        INC(FieldsCount);
        VerLanguageName(LangID,@LangName,256);
        INC(FieldsCount);
        // �����-����������� - ������ �����:
        FileVer :=
          IntToStr(pffi^.dwFileVersionMS shr 16) + '.' +
          IntToStr(pffi^.dwFileVersionMS shl 16 shr 16) + '.' +
          IntToStr(pffi^.dwFileVersionLS shr 16) + '.' +
          IntToStr(pffi^.dwFileVersionLS shl 16 shr 16);
        INC(FieldsCount);
        // �����-����������� - ������ ��������:
        ProductVer :=
          IntToStr(pffi^.dwProductVersionMS shr 16) + '.' +
          IntToStr(pffi^.dwProductVersionMS shl 16 shr 16) + '.' +
          IntToStr(pffi^.dwProductVersionLS shr 16) + '.' +
          IntToStr(pffi^.dwProductVersionLS shl 16 shr 16);
        INC(FieldsCount);
        // �����-����������� - ��� ������:
        if (pffi^.dwFileFlags and VS_FF_DEBUG)<>0 then
          BuildType := BuildType + 'debug, ';
        if (pffi^.dwFileFlags and VS_FF_INFOINFERRED)<>0 then
          BuildType := BuildType + 'info inferred, ';
        if (pffi^.dwFileFlags and VS_FF_PATCHED)<>0 then
          BuildType := BuildType + 'patched, ';
        if (pffi^.dwFileFlags and VS_FF_PRERELEASE)<>0 then
          BuildType := BuildType + 'prerelease, ';
        if (pffi^.dwFileFlags and VS_FF_PRIVATEBUILD)<>0 then
          BuildType := BuildType + 'private build, ';
        if (pffi^.dwFileFlags and VS_FF_SPECIALBUILD)<>0 then
          BuildType := BuildType + 'special build, ';
        if BuildType<>EmptyStr then
          Delete(BuildType,Length(BuildType)-1,2);
        INC(FieldsCount);
        // �����-����������� - ��� ����������� �����:
        if (pffi^.dwFileType and VFT_UNKNOWN)<>0 then
          FileType := 'unknown'
        else if (pffi^.dwFileType and VFT_APP)<>0 then
          FileType := 'application'
        else if (pffi^.dwFileType and VFT_DLL)<>0 then
          FileType := 'DLL'
        else if (pffi^.dwFileType and VFT_DRV)<>0 then
          FileType := 'driver'
        else if (pffi^.dwFileType and VFT_FONT)<>0 then
          FileType := 'font'
        else if (pffi^.dwFileType and VFT_VXD)<>0 then
          FileType := 'VXD'
        else if (pffi^.dwFileType and VFT_STATIC_LIB)<>0 then
          FileType := 'static lib';
        INC(FieldsCount);
      end;
      // string and var information - locale depended:
      if VerQueryValue(pbuff,'\VarFileInfo\Translation',pk,nk) then
      with InfoRecord do begin
        // language and codepage information:
        LangID := TLangRec(pk^)[0];
        INC(FieldsCount);
        LangCP := TLangRec(pk^)[1];
        INC(FieldsCount);
        VerLanguageName(LangID,@LangName,256);
        INC(FieldsCount);
        lang_hex_str := Format('%.4x',[LangID]) + Format('%.4x',[LangCP]);
        // string information - ��������� �� ����� ����������:
        for i := Low(TFviTags) to High(TFviTags) do
          if VerQueryValue(pbuff,PChar('\\StringFileInfo\\'+lang_hex_str+'\\'+
            cFviFieldsDef[i]),pk,nk) then
          begin
            FieldDef[i] := cFviFieldsDef[i];
            if LangId = RusLangID then
              FieldRus[i] := cFviFieldsRus[i]
            else
              FieldRus[i] := '';
            Value[i] := String(PChar(pk));
            INC(FieldsCount);
          end;
      end;
    end;
  finally
    if pbuff<>Nil then
      FreeMem(pbuff);
  end
end;

////////////////////////////////////////////////////////////////////////////////

var
  fc: Integer;

initialization

  try
    GetFileVersionInfoRecord(ParamStr(0),AppFileInfo,fc);
    AppInfoFound := fc <> 0;
  except
    AppInfoFound := False;
  end;

end.
