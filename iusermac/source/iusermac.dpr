program Project1;

{$APPTYPE CONSOLE}

uses
  SysUtils, classes, forms, MySQLServer, IniFiles, MySQLDataset, MyUnit, windows;

var
	MySqlServ: TMySQLServer;
  IniFile: TIniFile;

function SCharToOem(const AnsiStr: string): string;
begin
  SetLength(Result, Length(AnsiStr));
  if Length(Result) > 0 then
    CharToOem(PChar(AnsiStr), PChar(Result));
end;

function SOemToChar(const AnsiStr: string): string;
begin
  SetLength(Result, Length(AnsiStr));
  if Length(Result) > 0 then
    OemToChar(PChar(AnsiStr), PChar(Result));
end;

function ExchangeChars(S: string; FromChar, ToChar: Char): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    if S[I] = FromChar then
      Result := Result + ToChar
    else
      Result := Result + S[I];
  end; {for}
end;

function freadline(const afilename: string): string;
const
  BUFSIZE = 8192;
var
  fs: tfilestream;
  buf: packed array[0..BUFSIZE-1] of char;
  bufread: integer;
  bufpos: pchar;
  s, FramedIPAddress, CiscoAVPAIR, UserName, sDT: string;
  DT: TDateTime;
  i, nline: longint;
  Parsed: boolean;
  strSQL,stFileErr,stFileMAC: string;
begin
  with TMySQLDataset.Create(nil) do
  try
    Server := MySQLServ;

//    writeln(format('begin: %s',[FORMATDATETIME('yyyy.mm.dd hh:mm:ss', now())]));
//    writeln('');

    stFileErr := ChangeFileExt(afilename, '.err');
    stFileMAC := ChangeFileExt(afilename, '.mac');

    fs := tfilestream.create(afilename, fmopenread or fmShareDenyWrite);
    try
      nline:=0;
      FramedIPAddress := '';
      CiscoAVPAIR := '';
      UserName := '';
      Parsed := false;

      bufread := 0;
      bufpos := nil;

      repeat
        bufread := fs.Read(buf, BUFSIZE);
        bufpos := buf;

        for i := 0 to bufread - 1 do begin

          application.processmessages;

          case bufpos^ of
            #0: {};
            #10: begin
                //Parsed Packet =
                //Cisco-AVPAIR : String Value = client-mac-address=
                //Framed-IP-Address : IPAddress =
                //User-Name : String Value =
                //Acct-Status-Type : Integer Value = 2
                if (Pos('Parsed Packet =', s) = 21) then
                begin
                    Parsed := true;
                    FramedIPAddress := '';
                    CiscoAVPAIR := '';
                    UserName := '';
                    //writeln(s);
                end;
                if Parsed=true then begin
                if Pos('Cisco-AVPAIR : String Value = client-mac-address=', s) = 21 then begin
                  CiscoAVPAIR := copy(s, 70, 14);
                  //DT := StrToDateTime(ExchangeChars(copy(s, 1, 19), '/', DateSeparator));
                  DT := StrToDateTime(copy(s, 4, 2)+'.'+copy(s, 1, 2)+'.'+copy(s, 7, 4)+copy(s, 11, 9));
                  //CiscoAVPAIR := s;
                  //writeln(s);
                end;
                if Pos('Framed-IP-Address : IPAddress =', s) = 21 then begin
                  FramedIPAddress := copy(s, 53, length(s)-52);
                  //FramedIPAddress := s;
                  //writeln(s);
                end;
                if Pos('User-Name : String Value =', s) = 21 then begin
                  UserName := copy(s, 48, length(s)-47);
                  //UserName := s;
                  //writeln(s);
                end;
                if Pos('Acct-Status-Type : Integer Value = 2', s) = 21 then
                begin
                  //writeln(s);
                  if (FramedIPAddress<>'') and (CiscoAVPAIR<>'') and (UserName<>'') then begin
                    // запись
//                    writeln(format('%s  %15s  %s  %s',[FORMATDATETIME('yyyy.mm.dd hh:mm:ss', DT), FramedIPAddress, CiscoAVPAIR, UserName]));
                    AppendToFiles(format('%s  %15s  %s  %s',[FORMATDATETIME('yyyy.mm.dd hh:mm:ss', DT), FramedIPAddress, CiscoAVPAIR, UserName]),stFileMac);
                    strSQL:=format('insert into accountingmac (DT, IPAddress, ClientMacAddress, UserName) values ("%s", inet_aton("%s"), "%s", "%s") ',[FORMATDATETIME('yyyy.mm.dd hh:mm:ss', DT), FramedIPAddress, CiscoAVPAIR, UserName]);
                          //HexStr(pchar(strTextFile), length(strTextFile))]);
                    try
                      ExecSQL(strSQL);
                    except
                      on E: exception do
                      begin
                        AppendToLog(E.Message);
                        AppendToFiles(strSQL,stFileErr);
                      end;  //on
                    end;

                  end;
                  FramedIPAddress := '';
                  CiscoAVPAIR := '';
                  UserName := '';
                  Parsed := false;
                end;
                end;
                s := '';
              end;
            #13: {};
          else
            s := s + bufpos^;
          end;

          inc(bufpos);

        end;

      until (bufread < BUFSIZE);

    finally
      fs.free;
    end;

//    writeln(format('end: %s',[FORMATDATETIME('yyyy.mm.dd hh:mm:ss', now())]));
//    writeln('');

  finally
    Free;
  end;  //try
end;

begin
  if (paramstr(1) <> '') then begin
    Writeln('Import UsersMAC console 0.01    Copyright (c) 2010 Sasha Skrobat');
    AppendToLog('');
    AppendToLog('-- ' + DateTimeToStr(now) + '--');

    MySqlServ := TMySQLServer.Create(nil);
    TRY
      if not FileExists(ChangeFileExt(Application.ExeName, '.ini')) then begin
        IniFile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
        AppendToLog('Файл настроек не найден, создаю новый');
        TRY
          IniFile.WriteString('Login', 'IP', 'Localhost');
          IniFile.WriteString('Login', 'Port', '3306');
          IniFile.WriteString('Login', 'UserName', 'root');
          IniFile.WriteString('Login', 'Password', '');
          IniFile.WriteString('Login', 'DatabaseName', 'Radius');
        EXCEPT
          AppendToLog('Немогу записать INI файл');
          Abort;
        END; {try}
      end;
      IniFile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
      TRY
        MySqlServ.Host         := IniFile.ReadString('Login', 'Ip', 'localhost');
        MySqlServ.Port         := IniFile.ReadInteger('Login', 'Port', 3306);
        MySqlServ.UserName     := IniFile.ReadString('Login', 'UserName', 'root');
        MySqlServ.Password     := IniFile.ReadString('Login', 'Password', 'password');
        MySqlServ.DatabaseName := IniFile.ReadString('Login', 'DatabaseName', 'radius');
      EXCEPT
        AppendToLog('Не удалось открыть INI файл, аварийный выход');
        Abort;
      END; {try}

      TRY
        MySqlServ.Connected:=true;
      EXCEPT
        on E: exception do
             AppendToLog(E.Message);
      END;

      freadline(paramstr(1));
      //write(freadline(paramstr(1)));

     	MySQLServ.Close;
    finally
      MySQLServ.Free;
      MySQLServ := nil;
      writeln(format('end: %s',[FORMATDATETIME('yyyy.mm.dd hh:mm:ss', now())]));
      Writeln(SCharToOem('Обработка закончена. ENTER'));
    end;  //try
  end;
end.

