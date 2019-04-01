#SingleInstance,Force
global wb,Main,IE,Snake
SetBatchLines,-1
Gui,+hwndMain
Gui,Margin,0,0
new Settings()
Snake:=new SnakeClass(),Snake.Stop:=0
Settings.Show()
Gui,Show,,Snake
Sleep,100
return
Start(){
	Snake:=new SnakeClass(),Snake.Stop:=0
	Snake.Sleep:=100
	Guicontrol,+Redraw,%IE%
	Snake.BodyLength:=Settings.SSN("//Snake/@Length").text-1,Snake.AddBody(),Snake.ShowScore()
	Snake.Move(1)
}
return
+Escape::
Settings.Save()
ExitApp
return
Settings(){
	Input:=Snake.Doc.GetElementById("Input")
	if(!Input)
		Input.Value:=4
	Vis:=Snake.Settings.Style.Visibility
	if(Vis="Visible"){
		Snake.Settings.Style.Visibility:="Hidden"
		SetTimer,Start,-1
		New Settings()
	}else{
		Settings.Show(),Snake.Move()
	}
}
GuiClose:
Settings.Save()
ExitApp
return
Movement(){
	static Problem:={S:"N",N:"S",E:"W",W:"E"},Direction:={Up:"N",Down:"S",Left:"W",Right:"E"}
	Left:
	Right:
	Up:
	Down:
	D:=Direction[A_ThisLabel]
	if(Snake.MoveQueue.1){
		Queue:=Snake.MoveQueue[Snake.MoveQueue.MaxIndex()]
		if(Problem[Queue]!=D)
			Snake.MoveQueue.Push(D)
	}else if(Problem[D]!=Snake.Direction&&D!=Snake.Direction){
		Snake.MoveQueue.Push(D),LastDirection:=Direction
		total:=""
		for a,b in Snake.MoveQueue
			total.=b "`n"
	}
	return
}
m(x*){
	for a,b in x
		msg.=b "`n"
	MsgBox,,Snake,%msg%
}
t(x*){
	for a,b in x
		msg.=b "`n"
	ToolTip,%msg%
}
FixIE(Version=0){
	static Key:="Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION",Versions:={7:7000,8:8888,9:9999,10:10001,11:11001}
	Version:=Versions[Version]?Versions[Version]:Version
	if(A_IsCompiled)
		ExeName:=A_ScriptName
	else
		SplitPath,A_AhkPath,ExeName
	RegRead,PreviousValue,HKCU,%Key%,%ExeName%
	if(!Version)
		RegDelete,HKCU,%Key%,%ExeName%
	else
		RegWrite,REG_DWORD,HKCU,%Key%,%ExeName%,%Version%
	return PreviousValue
}
Class SnakeClass{
	__New(){
		static init
		if(!init){
			Default:=FixIE(12)
			Gui,Add,ActiveX,% "vwb w" Settings.BoardWidth " h" Settings.BoardHeight " hwndIE",mshtml
			init:=1,FixIE(Default)
		}wb.Navigate("about:<html><script>onerror=function(event){return true;};onmessage=function(event){return false;};onclick=function(event){ahk_event('OnClick',event);};onchange=function(event){ahk_event('OnChange',event);};oninput=function(event){ahk_event('OnInput',event);};onprogresschange=function(event){ahk_event('OnProgressChange',event);};</script><body style='background-color:Black;margin:0px;'><div id='Settings' Style='Visibility:Hidden'></div><svg></svg></body></html>")
		while(wb.ReadyState!=4)
			Sleep,10
		this.IE:=wb,this.IE.Document.ParentWindow.ahk_event:=Settings._Event.Bind(Settings),this.Doc:=this.IE.Document
		this.Body:=[],this.Taken:=[],this.AppleVis:=this.Score:=this.Length:=0,this.MoveQueue:=[]
		this.Settings:=this.Doc.GetElementById("Settings"),this.Difficulty:=10,this.Init:=1,this.Direction:="W"
		this.svg:=wb.Document.GetElementsByTagName("svg").item[0],this.Shape:="Rectangle",defs:=this.Doc.CreateElementNS("http://www.w3.org/2000/svg","defs")
		Rad:=this.Doc.CreateElementNS("http://www.w3.org/2000/svg","radialGradient")
		for a,b in {id:"grad2"}
			Rad.SetAttribute(a,b)
		for a,b in [{offset:"0%","stop-color":RGB(Settings.Body1)},{offset:"95%","stop-color":RGB(Settings.Body2)}]{
			Stop:=this.Doc.CreateElementNS("http://www.w3.org/2000/svg","stop")
			for c,d in b
				Stop.SetAttribute(c,d)
			Rad.AppendChild(Stop)
		}defs.AppendChild(Rad),this.SVG.AppendChild(Defs),this.AppleObj:=wb.Document.CreateElementNS("http://www.w3.org/2000/svg","circle")
		for a,b in {r:Settings.Size/2,fill:"Red",cx:0,cy:0,visibility:"hidden",stroke:"black"}
			this.AppleObj.SetAttribute(a,b)
		this.svg.AppendChild(this.AppleObj)
		return this
	}
	AddBody(){
		Shape:=this.Shape="Rectangle"?"rect":"circle",rect:=wb.Document.CreateElementNS("http://www.w3.org/2000/svg",Shape),this.svg.AppendChild(rect)
		if(!this.Body.1){
			x:=Floor((Width:=(Settings.BoardWidth-Settings.Size)/2)+Mod(Width,Settings.Size)),y:=Floor((Height:=(Settings.BoardHeight-Settings.Size)/2)+Mod(Height,Settings.Size)),rect.ID:="Head"
			New.SetAttribute("id","head")
		}else
			obj:=this.Body[this.Body.MaxIndex()],x:=obj.x,y:=obj.y
		this.Body.Push({rect:rect,x:x,y:y,xml:New})
		if(!this.Gradient){
			Colors:=[]
			for a,Fill in [Settings.Body1,Settings.Body2]{
				for a,b in {R:Fill&0xFF,G:(Fill&0x00FF00)>>8,B:Fill>>16}{
					if(!IsObject(Obj:=Colors[a]))
						Obj:=Colors[a]:=[]
					Obj[b]:=1
				}
			}Fill:=0
			for a,b in Colors{
				Random,Color,% b.MinIndex(),% b.MaxIndex()
				if(a="R")
					Fill|=Color
				if(a="G")
					Fill|=Color<<8
				if(a="B")
					Fill|=Color<<16
			}Fill:=RGB(this.Init?Settings.SSN("//Snake/@Head").text:Fill),this.Init:=0
		}else
			Fill:=this.Init?RGB(Settings.SSN("//Snake/@Head").text):"url(#grad2)",this.Init:=0
		obj:=this.Shape="Rectangle"?{x:0,y:0,width:Settings.Size,height:Settings.Size,stroke:"black",fill:Fill,transform:"translate(" x "," y ")"}:{cx:0,cy:0,r:Settings.Size/2,stroke:"black",fill:Fill,transform:"translate(" x "," y ")"}
		for a,b in obj
			Rect.SetAttribute(a,b)
		Head:=Snake.Doc.GetElementById("Head"),Head.ParentNode.AppendChild(Head)
		/*
			create a color cycling option to go with this one
			Red, Blue, Red, Blue and so on.
		*/
	}
	Apple(){
		pos:=this.Random(),x:=pos.x,y:=pos.y,SnakePos:=Snake.Body.1,StartX:=x,StartY:=y
		while(this.Taken[x,y]||(SnakePos.x=x&&SnakePos.y=y)){
			x:=x>=Settings.BoardWidth-Settings.Size?0:x+Settings.Size
			if(x=StartX)
				y:=y>=Settings.BoardHeight-Settings.Size?0:y+Settings.Size
			if(x=StartX&&y=StartY){
				m("All spaces taken",A_Index)
				this.Stop:=1
				SetTimer,Start,-100
				return
		}}this.AppleX:=x,this.AppleY:=y,Style:=this.AppleObj.Style
		if(Style.Visibility!="Visible")
			Style.visibility:="Visible"
		this.AppleObj.SetAttribute("transform","translate(" this.AppleX+Settings.Size/2 " " this.AppleY+Settings.Size/2 ")"),this.AppleVis:=1
	}
	Move(Start:=0){
		if(Start){
			SetTimer,Move,1
			return
			Index:=0
			Move:
			if(Snake.AppleObj.Style.Visibility!="Visible")
				Snake.Apple()
			if(Snake.BodyLength)
				Snake.AddBody(),Snake.BodyLength--,Snake.ShowScore()
			if(Direction:=Snake.MoveQueue.RemoveAt(1))
				Snake.Direction:=Direction
			if(Snake.Direction~="(E|W)")
				AddX:=Snake.Direction="E"?Settings.Size:-Settings.Size,AddY:=0
			else
				AddY:=Snake.Direction="N"?-Settings.Size:Settings.Size,AddX:=0
			Total:=all.Length,Tick:=A_TickCount,total:="",max:=Snake.Body.MaxIndex()
			Loop,%Max%{
				Current:=Max-(A_Index-1),b:=Snake.Body[Current],a:=Snake.Body[Current-1]
				if(Current=1)
					b.x+=AddX,b.y+=AddY,b.x:=b.x<0?Settings.BoardWidth-Settings.Size:b.x>=Settings.BoardWidth?0:b.x,b.y:=b.y<0?Settings.BoardHeight-Settings.Size:b.y>=Settings.BoardHeight?0:b.y,b.x:=Floor(b.x),b.y:=Floor(b.y)
				else
					Snake.Taken[b.x:=a.x,b.y:=a.y]:=1
				b.rect.SetAttribute("transform","translate(" (Snake.Shape="Rectangle"?b.x:b.x+(Settings.Size/2)) " " (Snake.Shape="Rectangle"?b.y:b.y+(Settings.Size/2)) ")")
			}Elapsed:=A_TickCount-Tick
			if((Sleep:=Snake.Sleep-Elapsed)>0&&!GetKeyState(Settings.Zoom,"P"))
				Sleep,%Sleep%
			if(Snake.AppleX=b.x&&Snake.AppleY=b.y){
				Snake.Score++,Snake.Apple(),Snake.AddBody(),Snake.ShowScore()
			}if(Snake.Taken[b.x,b.y]&&!Settings.Zen){
				MsgBox,20,Snake,% "Game Over`n`nScore: " Snake.Score "`n`nPlay Again?"
				IfMsgBox,Yes
				{
					this.Stop:=1
					Start()
					return
				}else
					ExitApp
			}Snake.Taken:=[]
			if(Snake.Stop)
				SetTimer,Move,Off
			return
		}else
			SetTimer,Move,Off
	}
	Random(){
		x:=Floor((Settings.BoardWidth-Settings.Size)/Settings.Size),y:=Floor((Settings.BoardHeight-Settings.Size)/Settings.Size)
		Random,x,0,%x%
		Random,y,0,%y%
		return {x:x*Settings.Size,y:y*Settings.Size}
	}
	ShowScore(){
		WinSetTitle,ahk_id%Main%,,% "Snake: Score " this.Score " Length: " this.Body.MaxIndex() " Mode: " (Settings.Zen?"Zen":"Normal")
	}
}
Class Settings{
	_Event(Name,Event){
		static
		Node:=Event.srcElement,Node:=Node.NodeName="Div"?Node:Node.ParentNode
		if(Name="OnChange"){
			if(Select:=Node.GetElementsByTagName("select").Item[0]){
				if(InStr(Select.ID,"Board")){
					Settings.SSN("//Board/@" Select.ID).text:=Select.Value
					ea:=Settings.EA("//Board")
					Gui,Show,% "w" ea.BoardWidth " h" ea.BoardHeight " Center"
					GuiControl,Move,%IE%,% "w" ea.BoardWidth " h" ea.BoardHeight
					Settings.Update(),Settings.Show()
				}else{
					Settings.SSN("//Snake/@Size").text:=Select.Value,Settings.Update()
				}
			}
		}
		else if(Name="OnClick"){
			if(ID:=Node.ID){
				if(ID="ZenObj")
					Settings.Zen:=1,Node.Style.Color:="Blue",Settings.Normal.Style.Color:="Grey",Settings.SSN("//Snake").SetAttribute("Zen",1)
				else if(ID="Normal")
					Settings.Zen:=0,Node.Style.Color:="Blue",Settings.ZenObj.Style.Color:="Grey",Settings.SSN("//Snake").SetAttribute("Zen",0)
				else if(ID~="(Head|Body1|Body2)"){
					Color:=Dlg_Color(Settings[ID],Main)
					Node.Style.Color:=RGB(Color)
					Settings.SSN("//Snake/@" ID).text:=Color
				}else if(ID~="(Up|Down|Left|Right|Zoom|Settings)"){
					static Hotkey
					Text:=Node.OuterHtml
					Gui,2:Destroy
					Gui,2:Default
					Gui,Color,0,0
					Gui,Add,Hotkey,w200 vHotkey c0xAAAAAA,% Settings[ID]
					Gui,Add,Edit,gUpdateHotkey vHK w200 c0xAAAAAA
					Gui,Add,Button,gSetHotkey Default,Set Hotkey
					Gui,Show
					return
					UpdateHotkey:
					Gui,2:Submit,Nohide
					GuiControl,2:,msctls_hotkey321,%HK%
					return
					SetHotkey:
					Gui,2:Submit,Nohide
					Gui,2:Destroy
					if(!Hotkey)
						return
					StringUpper,Hotkey,Hotkey,T
					Settings.SSN("//Controls/@" ID).text:=Hotkey
					Node.OuterHtml:=SubStr(Text,1,InStr(Text,">",0,0,3)) Hotkey SubStr(Text,InStr(Text,"<",0,0,2))
					Settings.Update()
					return
				}else if(ID="Size")
					Settings.SSN("//Snake/@Size").text:=Node.Value,Settings.Update()
				else
					MsgBox,% "Coming Soon..." ID
				Settings.Update()
			}
		}else if(Name="OnInput"){
			Input:=Snake.Doc.GetElementById("Input"),Selection:=Input.SelectionStart
			Input.Value:=RegExReplace(Input.Value,"\D",,Count)
			if(Count)
				Input.SelectionStart:=Selection-1,Input.SelectionEnd:=Selection-1
			if(Input.Value>500)
				Input.Value:=500
			if(Input.Value)
				Settings.SSN("//Snake/@Length").text:=Input.Value
			Settings.Update()
		}else if(Name="OnSelect"){
			m("YAY")
		}
		Snake.Doc.GetSelection().RemoveAllRanges()
	}__New(){
		if(!IsObject(Settings.XML)){
			XML:=Settings.XML:=ComObjCreate("MSXML2.DOMDocument"),XML.SetProperty("SelectionLanguage","XPath")
			(FileExist("Settings.xml"))?XML.Load("Settings.xml"):XML.AppendChild(Settings.CreateElement("Settings"))
		}this.Update()
	}Add(XPath,Att:="",Text:="",Dup:=0){
		Obj:=StrSplit(XPath,"/")
		if(!Node:=Settings.SSN("//" XPath)){
			for a,b in Obj
				(!Exist:=Settings.SSN("//" Trim(Build.=b "/","/")))?(Node:=(A_Index=1?Settings.SSN("//*"):Node).AppendChild(Settings.CreateElement(b))):(Node:=Exist)
		}else if(Dup)
			Node:=Node.ParentNode.AppendChild(Settings.CreateElement(Obj.Pop()))
		for a,b in Att
			Node.SetAttribute(a,b)
		if(Text)
			Node.Text:=Text
		return Node
	}CreateElement(Node){
		return Settings.XML.CreateElement(Node)
	}Div(Parent,Width,Height,MarginLeft,MarginTop,Border:="1px Solid Blue",Radius:=4){
		Div:=Snake.Doc.CreateElement("div"),Style:=Div.Style
		for a,b in {Width:Width,Height:Height,BorderRadius:Radius "px",Border:Border,Display:"Block",VerticalAlign:"Middle",TextAlign:"Center",MarginLeft:MarginLeft,MarginTop:MarginTop,Float:"Left",LineHeight:"10px"}
			Style[a]:=b
		Parent.AppendChild(Div)
		return Div
	}EA(Node){
		Obj:=[],all:=Node.NodeName?Node.SelectNodes("@*"):Settings.SN(Node "/@*")
		while(aa:=all.item[A_Index-1])
			Obj[aa.NodeName]:=aa.Text
		return Obj
	}Hotkey(){
		Hotkey:
		Action:=Settings.SSN("//Controls/@*[.='" A_ThisHotkey "']").NodeName
		if(IsLabel(Action))
			SetTimer,%Action%,-1
		else if(IsFunc(Action))
			%Action%()
		return
	}Hotkeys(Enable:=1){
		static
		for a,b in LastHotkeys
			Hotkey,%b%,Hotkey,Off
		LastHotkeys:=[]
		Hotkey,IfWinActive,ahk_id%main%
		all:=Settings.SN("//Controls/@*")
		while(aa:=all.item[A_Index-1]){
			Hotkey,% aa.text,Hotkey,% Enable?"On":"Off"
			LastHotkeys[aa.NodeName]:=aa.text
		}
	}P(Parent,InnerHtml,StyleObj){
		Item:=Snake.Doc.CreateElement("p"),Item.InnerHtml:=InnerHtml,Parent.AppendChild(Item),Style:=Item.Style
		for a,b in StyleObj
			Style[a]:=b
		return Item
	}Save(){
		static
		if(!IsObject(xsl))
			xsl:=ComObjCreate("MSXML2.DOMDocument"),xsl.loadXML("<xsl:stylesheet version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform""><xsl:output method=""xml"" indent=""yes"" encoding=""UTF-8""/><xsl:template match=""@*|node()""><xsl:copy>`n<xsl:apply-templates select=""@*|node()""/><xsl:for-each select=""@*""><xsl:text></xsl:text></xsl:for-each></xsl:copy>`n</xsl:template>`n</xsl:stylesheet>")
		Settings.XML.TransformNodeToObject(xsl,Settings.xml),Settings.XML.Save(A_ScriptDir "\Settings.xml")
	}Show(){
		static Obj:=[]
		Win:=Snake.Settings,Win.Style.Visibility:="Visible"
		Try
			if(Things:=Snake.Doc.GetElementById("Things"))
				Things.ParentNode.RemoveChild(Things)
		Things:=Snake.Doc.CreateElement("div"),Things.ID:="Things",Win.AppendChild(Things)
		Width:=Floor(Settings.BoardWidth/5)
		TotalHeight:=40+200+100+40
		Spacing:=Floor((Settings.BoardHeight-TotalHeight)/7)
		for a,b in [["Head Color","Head"],["Body Color 1","Body1"],["Body Color 2","Body2"]]
			p:=this.P(this.Div(Things,Width,40,((Width/2)),Spacing,,15),"<u>" b.1 "</u>",{Color:RGB(Settings.SSN("//Snake/@" b.2).text),Cursor:"Hand"}),p.ID:=b.2
		Space:=Width:=Floor(Settings.BoardWidth/7)
		if(Space<125)
			Space:=Floor((Settings.BoardWidth-375)/4)
		this.P((Div:=this.Div(Things,(Width<125?125:Width),200,Space,Spacing,,20)),"Controls:",{Color:"Red"})
		for a,b in Settings.EA("//Controls")
			this.P(Div,a " - <u style='Cursor:Hand'>" b "</u>",{Color:"White"}).ID:=a
		this.P((Div:=this.Div(Things,(Width<125?125:Width),200,Space,Spacing,,20)),"Board Width:",{Color:"Red"})
		Select:=Snake.Doc.CreateElement("select"),Select.ID:="BoardWidth"
		ww:=400,hh:=400
		Div.AppendChild(Select),Select.Size:=9,Select.Style.BackgroundColor:="Black",Select.Style.Color:="White"
		while((ww+=100)<A_ScreenWidth){
			Option:=Snake.Doc.CreateElement("option"),Select.AppendChild(Option),Option.InnerHtml:=ww
			Option.SetAttribute("onchange","onchange()")
			if(ww=Settings.BoardWidth)
				Option.Selected:=1
		}
		this.P((Div:=this.Div(Things,(Width<125?125:Width),200,Space,Spacing,,20)),"Board Height:",{Color:"Red"})
		Select:=Snake.Doc.CreateElement("select"),Select.ID:="BoardHeight"
		Div.AppendChild(Select),Select.Size:=9,Select.Style.BackgroundColor:="Black",Select.Style.Color:="White" ;,Select.Style.Height:=80
		while((hh+=100)<A_ScreenHeight){
			Option:=Snake.Doc.CreateElement("option"),Select.AppendChild(Option),Option.InnerHtml:=hh
			Option.SetAttribute("onchange","onchange()")
			if(hh=Settings.BoardHeight)
				Option.Selected:=1
		}Width:=Floor(Settings.BoardWidth/5),this.P((Div:=this.Div(Things,Width*2,120,Width/3,Spacing,,20)),"Game Type:",{Color:"Red"})
		for a,b in {Normal:"Normal",ZenObj:"Zen - Can Not Lose"}
			(Settings[a]:=this.P(Div,"<u>" b "</u>",{Color:((Settings.Zen&&a="ZenObj")||(!Settings.Zen&&a="Normal")?"Blue":"Grey"),Cursor:"Hand"})).ID:=a
		this.P((Div:=This.Div(Things,Width*2,120,Width/3,Spacing,,20)),"Snake:",{Color:"Red"})
		(Settings.Length:=this.P(Div,"Snake Length: <input id='Input' type='text' style='width:50;color:grey;background-color:black;' value='" Settings.SSN("//Snake/@Length").text "' autofocus/>",{Color:"White"}))
		Size:=this.P(Div,"Snake Size: ",{Color:"White"}),Select:=Snake.Doc.CreateElement("select"),Select.ID:="Size",Size.AppendChild(Select),Sizes:={(Settings.BoardWidth):1,(Settings.BoardHeight):1}
		while((Index:=A_Index+9)<=Sizes.MinIndex()-1){
			if(!Mod(Sizes.MinIndex(),Index)&&!Mod(Sizes.MaxIndex(),Index)){
				Option:=Snake.Doc.CreateElement("option"),Option.InnerHtml:=Index,Select.AppendChild(Option)
				if(Index=Settings.Size)
					Option.Selected:=1
			}
		}Width:=Floor(Settings.BoardWidth/3),this.P(this.Div(Things,Width<200?200:Width,40,Width<200?(Settings.BoardWidth-200)/2:Width,Spacing,,10),"Press the Settings Key to Start",{Color:"White"}),Snake.Doc.GetElementById("Input").Select()
		return
	}SN(XPath){
		return Settings.XML.SelectNodes(XPath)
	}SSN(XPath,Other:=""){
		return (Other?XPath:Settings.XML).SelectSingleNode((Other?Other:XPath))
	}Update(){
		Node:=Settings.Add("Board")
		for a,b in {BoardWidth:500,BoardHeight:500}{
			if((Value:=Settings.SSN(Node,"@" a).text)<b)
				Node.SetAttribute(a,b),Value:=b
			Settings[a]:=Value
		}
		Node:=Settings.Add("Controls")
		for a,b in {Left:"Left",Right:"Right",Up:"Up",Down:"Down",Settings:"Escape",Zoom:"A"}{
			if(!Value:=Settings.SSN(Node,"@" a).text)
				Node.SetAttribute(a,b),Value:=b
			Settings[a]:=Value
		}this.Hotkeys(),Node:=Settings.Add("Snake")
		for a,b in {Length:4,Head:255,Body1:0x00FF00,Body2:0x009900,Zen:0,Size:10}{
			if(!Value:=Settings.SSN(Node,"@" a).text)
				Node.SetAttribute(a,b),Value:=b
			Settings[a]:=Value
		}
	}
}
Dlg_Color(Color,hwnd){
	static
	if !cc{
		VarSetCapacity(CUSTOM,16*A_PtrSize,0),cc:=1,size:=VarSetCapacity(CHOOSECOLOR,9*A_PtrSize,0)
		Loop,16{
			IniRead,col,Settings.ini,CustomColors,%A_Index%,0
			NumPut(col,CUSTOM,(A_Index-1)*4,"UInt")
	}}NumPut(size,CHOOSECOLOR,0,"UInt"),NumPut(hwnd,CHOOSECOLOR,A_PtrSize,"UPtr"),NumPut(Color,CHOOSECOLOR,3*A_PtrSize,"UInt"),NumPut(3,CHOOSECOLOR,5*A_PtrSize,"UInt"),NumPut(&CUSTOM,CHOOSECOLOR,4*A_PtrSize,"UPtr"),ret:=DllCall("comdlg32\ChooseColor","UPtr",&CHOOSECOLOR,"UInt")
	if(!ret)
		Exit
	Loop,16
		IniWrite,% NumGet(CUSTOM,(A_Index-1)*4,"UInt"),Settings.ini,CustomColors,%A_Index%
	Color:=NumGet(CHOOSECOLOR,3*A_PtrSize,"UInt")
	return Color
}
RGB(c){
	SetFormat,integer,H
	for a,b in [c&0xFF,(c&0x00FF00)>>8,c>>16]
		total.=Format("{:02}",SubStr(b,3))
	SetFormat,integer,D
	return "#" total
}
