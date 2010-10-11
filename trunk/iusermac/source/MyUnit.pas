unit MyUnit;

interface

uses
  sysutils, classes, forms;

procedure AppendToLog(StringList: TStrings); overload;
procedure AppendToLog(StringList: string); overload;
procedure AppendToFiles(StringList: TStrings; stFile: string); overload;
procedure AppendToFiles(StringList: string; stFile: string); overload;


implementation


procedure AppendToLog(StringList: TStrings);
var
  stFile: string;
begin
  stFile := ChangeFileExt(Application.ExeName, '.log');
  //stFile := getcurrentdir + '\vpsren.log';
  AppendToFiles(StringList, stFile);
end;

procedure AppendToLog(StringList: string);
var
  stFile: string;
begin
  stFile := ChangeFileExt(Application.ExeName, '.log');
//  stFile := getcurrentdir + '\vpsren.log';
  AppendToFiles(StringList, stFile);
end;

procedure AppendToFiles(StringList: TStrings; stFile: string);
var
  Stream: TStream;
begin
//  stFile := ChangeFileExt(Application.ExeName, '.log');
  if not(FileExists(stFile)) then
    Stream := TFileStream.Create(stFile, fmCreate)
  else
    Stream := TFileStream.Create(stFile, fmOpenReadWrite or fmShareDenyWrite);
  Stream.Seek(0, soFromEnd);
  try
    StringList.SaveToStream(Stream);
  finally
    Stream.Free;
    Stream := nil;
  end;
end;

procedure AppendToFiles(StringList: string; stFile: string);
const
  NewLine: PChar = #13#10;
var
  Stream: TStream;
begin
//  stFile := ChangeFileExt(Application.ExeName, '.log');
  if not(FileExists(stFile)) then
    Stream := TFileStream.Create(stFile, fmCreate)
  else
    Stream := TFileStream.Create(stFile, fmOpenReadWrite or fmShareDenyWrite);
  Stream.Seek(0, soFromEnd);
  try
    Stream.Write(StringList[1], Length(StringList));
    writeln(StringList);
    Stream.Write(NewLine[0], 2);
  finally
    Stream.Free;
    Stream := nil;
  end;
end;


end.
