local e={}local t,a,o=require,{},{startup=e}
local function i(n)local s=o[n]
if s~=nil then if s==e then
error("loop or previous error loading module '"..n..
"'",2)end;return s end;o[n]=e;local h=a[n]if h then s=h(n)elseif t then s=t(n)else
error("cannot load '"..n.."'",2)end;if s==nil then s=true end;o[n]=s;return s end
a["vendor.uuid"]=function(...)local n=math.random
return
function()local s='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'return
string.gsub(s,'[xy]',function(h)local r=(
h=='x')and n(0,0xf)or n(8,0xb)return
string.format('%x',r)end)end end
a["vendor.serpent"]=function(...)local h,r="serpent","0.302"
local l,u="Paul Kulchenko","Lua serializer and pretty printer"
local c={[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}local m={thread=true,userdata=true,cdata=true}local f=
debug and debug.getmetatable or getmetatable
local w=function(n)return next,n end;local y,p,v={},{},(_G or _ENV)
for n,s in
ipairs({'and','break','do','else','elseif','end','false','for','function','goto','if','in','local','nil','not','or','repeat','return','then','true','until','while'})do y[s]=true end;for n,r in w(v)do p[r]=n end
for n,s in
ipairs({'coroutine','debug','io','math','string','table','os'})do for d,r in w(type(v[s])=='table'and v[s]or{})do p[r]=
s..'.'..d end end
local function b(n,s)local d,q,j,x=s.name,s.indent,s.fatal,s.maxnum
local z,_,E=s.sparse,s.custom,not s.nohuge
local T,A=(s.compact and''or' '),(s.maxlevel or math.huge)local O,I=tonumber(s.maxlength),s.metatostring
local N,S='_'.. (d or''),s.comment and(
tonumber(s.comment)or math.huge)local H=s.numformat or"%.17g"
local R,D,L,U={},{'local '..N..'={}'},{},0
local function C(J)
return'_'..
(tostring(tostring(J)):gsub("[^%w]",""):gsub("(%d%w+)",function(b)if
not L[b]then U=U+1;L[b]=U end;return tostring(L[b])end))end
local function M(b)
return
type(b)=="number"and
tostring(E and c[tostring(b)]or H:format(b))or
type(b)~="string"and tostring(b)or
("%q"):format(b):gsub("\010","n"):gsub("\026","\\026")end
local function F(b,J)return
S and(J or 0)<S and' --[['..
select(2,pcall(tostring,b))..']]'or''end;local function W(b,J)
return p[b]and p[b]..F(b,J)or not j and
M(select(2,pcall(tostring,b)))or
error("Can't serialize "..tostring(b))end
local function Y(J,d)local h=
d==nil and''or d;local X=
type(h)=="string"and h:match("^[%l%u_][%w_]*$")and not y[h]local Z=
X and h or'['..M(h)..']'return(J or'')..
(X and J and'.'or'')..Z,Z end
local P=type(s.sortkeys)=='function'and s.sortkeys or
function(J,X,h)
local Z,ee=tonumber(h)or 12,{number='a',string='b'}local function et(u)return
("%0"..tostring(Z).."d"):format(tonumber(u))end
table.sort(J,function(ea,eo)
return

(J[ea]~=
nil and 0 or ee[type(ea)]or'z').. (tostring(ea):gsub("%d+",et))<

(J[eo]~=nil and 0 or ee[type(eo)]or'z').. (tostring(eo):gsub("%d+",et))end)end
local function V(n,d,q,J,X,Z,ee)local et,ee,ea=type(n),(ee or 0),f(n)local eo,ei=Y(X,d)
local en=
Z and(
(type(d)=="number")and''or d..T..'='..T)or(d~=nil and ei..T..'='..T or'')if R[n]then D[#D+1]=eo..T..'='..T..R[n]return en..
'nil'..F('ref',ee)end
if
type(ea)=='table'and I~=false then
local es,eh=pcall(function()return ea.__tostring(n)end)
local er,ed=pcall(function()return ea.__serialize(n)end)
if(es or er)then R[n]=J or eo;n=er and ed or eh;et=type(n)end end
if et=="table"then
if ee>=A then return en..'{}'..F('maxlvl',ee)end;R[n]=J or eo
if next(n)==nil then return en..'{}'..F(n,ee)end
if O and O<0 then return en..'{}'..F('maxlen',ee)end;local es,eh,er=math.min(#n,x or#n),{},{}for em=1,es do eh[em]=em end;if not x or
#eh<x then local h=#eh
for em in w(n)do if eh[em]~=em then h=h+1;eh[h]=em end end end
if x and#eh>x then eh[x+1]=nil end;if s.sortkeys and#eh>es then P(eh,n,s.sortkeys)end;local z=z and
#eh>es
for h,em in ipairs(eh)do
local ef,ew,Z=n[em],type(em),h<=es and not z
if


s.valignore and s.valignore[ef]or
s.keyallow and not s.keyallow[em]or s.keyignore and s.keyignore[em]or s.valtypeignore and s.valtypeignore[type(ef)]or z and ef==nil then elseif ew=='table'or ew=='function'or m[ew]then if not R[em]and
not p[em]then D[#D+1]='placeholder'local ei=Y(N,C(em))
D[#D]=V(em,ei,q,ei,N,true)end;D[#D+1]='placeholder'local X=
R[n]..
'['..tostring(R[em]or p[em]or C(em))..']'D[#D]=X..
T..'='..T..tostring(R[ef]or
V(ef,nil,q,X))else
er[#er+1]=V(ef,em,q,nil,R[n],Z,ee+1)if O then O=O-#er[#er]if O<0 then break end end end end;local ed=string.rep(q or'',ee)
local el=q and'{\n'..ed..q or'{'
local eu=table.concat(er,','.. (q and'\n'..ed..q or T))local ec=q and"\n"..ed..'}'or'}'return
(
_ and _(en,el,eu,ec,ee)or en..el..eu..ec)..F(n,ee)elseif m[et]then R[n]=J or eo;return en..W(n,ee)elseif
et=='function'then R[n]=J or eo;if s.nocode then return
en.."function() --[[..skipped..]] end"..F(n,ee)end
local es,eh=pcall(string.dump,n)local er=es and
"((loadstring or load)("..M(eh)..",'@serialized'))"..F(n,ee)return en.. (er or
W(n,ee))else return en..M(n)end end;local B=q and"\n"or";"..T;local G=V(n,d,q)local K=#D>1 and
table.concat(D,B)..B or''
local Q=
s.comment and#D>1 and T..
"--[[incomplete output with shared/self-references skipped]]"or''
return not d and G..Q or"do local "..
G..B..K.."return "..d..B.."end"end
local function g(n,s)
local d=(s and s.safe==false)and v or
setmetatable({},{__index=function(x,z)return x end,__call=function(x,...)
error("cannot call functions")end})
local q,j=(loadstring or load)('return '..n,nil,nil,d)
if not q then q,j=(loadstring or load)(n,nil,nil,d)end;if not q then return q,j end;if setfenv then setfenv(q,d)end;return pcall(q)end
local function k(n,s)if s then for d,r in w(s)do n[d]=r end end;return n end
return
{_NAME=h,_COPYRIGHT=l,_DESCRIPTION=u,_VERSION=r,serialize=b,load=g,dump=function(n,s)
return b(n,k({name='_',compact=true,sparse=true},s))end,line=function(n,s)return
b(n,k({sortkeys=true,comment=true},s))end,block=function(n,s)return
b(n,k({indent='  ',sortkeys=true,comment=true},s))end}end
a["vendor.json"]=function(...)local n={_version="0.1.2"}local s
local h={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local r={["/"]="/"}for N,S in pairs(h)do r[S]=N end;local function d(N)
return"\\".. (h[N]or
string.format("u%04x",N:byte()))end;local function l(N)return"null"end
local function u(N,S)local H={}
S=S or{}if S[N]then error("circular reference")end;S[N]=true
if
rawget(N,1)~=nil or next(N)==nil then local R=0
for D in pairs(N)do if type(D)~="number"then
error("invalid table: mixed or invalid key types")end;R=R+1 end
if R~=#N then error("invalid table: sparse array")end;for D,L in ipairs(N)do table.insert(H,s(L,S))end
S[N]=nil;return"["..table.concat(H,",").."]"else for R,D in pairs(N)do if
type(R)~="string"then
error("invalid table: mixed or invalid key types")end
table.insert(H,s(R,S)..":"..s(D,S))end
S[N]=nil;return"{"..table.concat(H,",").."}"end end;local function c(N)
return'"'..N:gsub('[%z\1-\31\\"]',d)..'"'end
local function m(N)if N~=N or N<=-math.huge or
N>=math.huge then
error("unexpected number value '"..tostring(N).."'")end;return
string.format("%.14g",N)end
local f={["nil"]=l,["table"]=u,["string"]=c,["number"]=m,["boolean"]=tostring}
s=function(N,S)local H=type(N)local R=f[H]if R then return R(N,S)end
error("unexpected type '"..H.."'")end;function n.encode(N)return(s(N))end;local w
local function y(...)local N={}for S=1,select("#",...)do
N[select(S,...)]=true end;return N end;local p=y(" ","\t","\r","\n")
local v=y(" ","\t","\r","\n","]","}",",")local b=y("\\","/",'"',"b","f","n","r","t","u")
local g=y("true","false","null")local k={["true"]=true,["false"]=false,["null"]=nil}
local function q(N,S,H,R)for D=S,#N do if
H[N:sub(D,D)]~=R then return D end end;return#N+1 end
local function j(N,S,H)local R=1;local D=1
for L=1,S-1 do D=D+1;if N:sub(L,L)=="\n"then R=R+1;D=1 end end
error(string.format("%s at line %d col %d",H,R,D))end
local function x(N)local S=math.floor
if N<=0x7f then return string.char(N)elseif N<=0x7ff then return string.char(S(N/64)+192,
N%64+128)elseif N<=0xffff then
return string.char(S(N/4096)+
224,S(N%4096/64)+128,N%64+128)elseif N<=0x10ffff then
return string.char(S(N/262144)+240,S(N%262144/4096)+128,S(
N%4096/64)+128,N%64+128)end
error(string.format("invalid unicode codepoint '%x'",N))end
local function z(N)local S=tonumber(N:sub(1,4),16)
local H=tonumber(N:sub(7,10),16)if H then return
x((S-0xd800)*0x400+ (H-0xdc00)+0x10000)else return x(S)end end
local function _(N,S)local H=""local R=S+1;local D=R
while R<=#N do local L=N:byte(R)
if L<32 then
j(N,R,"control character in string")elseif L==92 then H=H..N:sub(D,R-1)R=R+1;local U=N:sub(R,R)
if U=="u"then
local C=
N:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",
R+1)or N:match("^%x%x%x%x",R+1)or j(N,R-1,"invalid unicode escape in string")H=H..z(C)R=R+#C else if not b[U]then
j(N,R-1,"invalid escape char '"..U.."' in string")end;H=H..r[U]end;D=R+1 elseif L==34 then H=H..N:sub(D,R-1)return H,R+1 end;R=R+1 end;j(N,S,"expected closing quote for string")end
local function E(N,S)local H=q(N,S,v)local R=N:sub(S,H-1)local D=tonumber(R)if not D then
j(N,S,"invalid number '"..R.."'")end;return D,H end
local function T(N,S)local H=q(N,S,v)local R=N:sub(S,H-1)if not g[R]then
j(N,S,"invalid literal '"..R.."'")end;return k[R],H end
local function A(N,S)local H={}local R=1;S=S+1
while 1 do local D;S=q(N,S,p,true)
if N:sub(S,S)=="]"then S=S+1;break end;D,S=w(N,S)H[R]=D;R=R+1;S=q(N,S,p,true)local L=N:sub(S,S)S=S+1
if L=="]"then break end;if L~=","then j(N,S,"expected ']' or ','")end end;return H,S end
local function O(N,S)local H={}S=S+1
while 1 do local R,D;S=q(N,S,p,true)
if N:sub(S,S)=="}"then S=S+1;break end
if N:sub(S,S)~='"'then j(N,S,"expected string for key")end;R,S=w(N,S)S=q(N,S,p,true)if N:sub(S,S)~=":"then
j(N,S,"expected ':' after key")end;S=q(N,S+1,p,true)D,S=w(N,S)H[R]=D
S=q(N,S,p,true)local L=N:sub(S,S)S=S+1;if L=="}"then break end;if L~=","then
j(N,S,"expected '}' or ','")end end;return H,S end
local I={['"']=_,["0"]=E,["1"]=E,["2"]=E,["3"]=E,["4"]=E,["5"]=E,["6"]=E,["7"]=E,["8"]=E,["9"]=E,["-"]=E,["t"]=T,["f"]=T,["n"]=T,["["]=A,["{"]=O}
w=function(N,S)local H=N:sub(S,S)local R=I[H]if R then return R(N,S)end
j(N,S,"unexpected character '"..H.."'")end
function n.decode(N)if type(N)~="string"then
error("expected argument of type string, got "..type(N))end
local S,H=w(N,q(N,1,p,true))H=q(N,H,p,true)
if H<=#N then j(N,H,"trailing garbage")end;return S end;return n end
a["shared.validate"]=function(...)local n={}local s=i("shared.apierrors")local function h(r,d)if type(r)~=d then
error({prim=d})end end
n.types={Color=function()return
function(r,d)h(r,"number")local l=1+ (
math.log(r)/math.log(2))return(l>=1 and
l<=16),s.WTYPE("COLOR",d)end end,String=function(r,d)
return
function(l,u)
h(l,"string")local c=#l
if r and c>r then return false,s.BOUND("# <= "..r,u)end
if d and c<d then return false,s.BOUND("# >= "..d,u)end;return true end end,Bool=function()return function(r)
h(r,"boolean")return true end end,Min=function(r)
return function(l,u)
h(l,"number")return l>=r,s.BOUND(">= "..r,u)end end,Max=function(r)
return function(l,u)h(l,"number")return l<=r,
s.BOUND("<= "..r,u)end end,Tab=function(r)return
function(l,u)return n:exec(l,r,u..".")end end}
function n:exec(r,d,l)l=l or""
if type(r)~="table"then return false,s.INVALIDREQ end
for u,c in pairs(d)do if r[u]==nil then return false,s.MISSING(u)end;local m=l..u
local f=r[u]
for w,y in ipairs(c)do local p,v,b=pcall(y,f,m)
if p then
if not v then return false,b or s.INVALIDREQ end else if type(v)=="table"and v.prim then return false,s.WTYPE(v.prim,m)else
return false,s.SVERR end end end end;return true end;setmetatable(n,{__call=n.exec})return n end
a["shared.tableutils"]=function(...)local n={}
local function s(h,r,d)if
(d and r==d+1)or not(d or h[r])then return end;return h[r],s(h,r+1)end
function n.unpack(h,r,d)
if table.unpack then return table.unpack(h,r,d)elseif _G["unpack"]then return
_G["unpack"](h,r,d)else return s(h,r or 1,d)end end
function n.postpack(h,...)local r={}local d={}local l={...}
for u=1,select("#",...)do if h>0 then
table.insert(r,l[u])h=h-1 else table.insert(d,l[u])end end;table.insert(r,d)return n.unpack(r)end
function n.proxycat(...)local h={...}local r={}local d=0;for u=1,#h do
for c=1,#h[u]do d=d+1;r[d]={h[u],c}end end;local function l(u)
for c=1,#h do if h[c][u]then return h[c][u]end end end;return
setmetatable({},{__index=function(u,c)if r[c]then
return r[c][1][r[c][2]]else return l(c)end end})end;return n end
a["shared.stringutils"]=function(...)local n={}
function n.explode(s,h)local r={}
while#h>0 do local d,l=h:find(s)if d then
table.insert(r,h:sub(1,d-1))table.insert(r,h:sub(d,l))h=h:sub(l+1)else
table.insert(r,h)break end end;return r end
function n.split(s,h)local r={}while#h>0 do local d,l=h:find(s)
if d then
table.insert(r,h:sub(1,d-1))h=h:sub(l+1)else table.insert(r,h)break end end;return r end;return n end
a["shared.socket.types"]=function(...)local n={}n.SocketType={INITIATOR=1,COMPANION=2}return n end
a["shared.socket"]=function(...)local n={}local s=i("vendor.uuid")
local h=i("shared.logger")local r=i("shared.async")local d=i("shared.funcutils")
local l=i("shared.socket.types")
n.backends={i("shared.socket.backends.modem")}local u;for m=1,#n.backends do
if n.backends[m].tryInit()then u=n.backends[m]break end end;if not u then
error("No socket backend could be initialized."..
" Please add attach a modem to your computer.")end;n.Socket={}
function n.Socket.new(m)
local f={uuid=s(),bsocket=m,handlers={},request_handlers={},active_requests={},hid=0,rid=0}
m:onRecieve(d.bind(n.Socket.handleMsg,f))
m:onDisconnect(function()if f.onDisconnect then f:onDisconnect()end end)
setmetatable(f,{__index=n.Socket,__tostring=n.Socket.tostring})return f end;function n.Socket:tostring()
return"Socket<"..tostring(self.bsocket)..">"end
function n.Socket:handleMsg(m)
h.debug("Socket message:",m)
if m.type=="event"then
if type(m.data)=="table"then
if self.handlers[m.event]then for f,w in
ipairs(self.handlers[m.event])do w.callback(m.data)end else
h.warn("Received unrouted event",m.event,m.data)end end elseif m.type=="request"then if type(m.rid)~="number"then return end
if
self.request_handlers[m.request]then
self.request_handlers[m.request]({succeed=function(f)
self.bsocket:write({ok=true,type="response",rid=m.rid,data=f})end,fail=function(f)
self.bsocket:write({ok=false,type="response",rid=m.rid,error=f})end},m.data)else
h.error("Invalid endpoint '"..m.request.."' requested")
self.bsocket:write({ok=false,type="response",rid=m.rid,error="No such request defined"})end elseif m.type=="response"then if type(m.rid)~="number"then return end
if
self.active_requests[m.rid]then
if m.ok then
self.active_requests[m.rid][1](m.data)self.active_requests[m.rid]=nil else
self.active_requests[m.rid][2](m.error)self.active_requests[m.rid]=nil end end end end;function n.Socket:handleDisconnect(m)self.onDisconnect=m end
function n.Socket:request(m,f)self.rid=(
self.rid+1)%2^32;return
r.Promise.new(function(w,y)
self.active_requests[self.rid]={w,y}
self.bsocket:write({type="request",request=m,rid=self.rid,data=f or{}})end)end;function n.Socket:emit(m,f)
self.bsocket:write({type="event",event=m,data=f})end;function n.Socket:handle(m,f)
self.request_handlers[m]=f end
function n.Socket:on(m,f)self.hid=self.hid+1;self.handlers[m]=
self.handlers[m]or{}
table.insert(self.handlers[m],{hid=self.hid,callback=f})return self.hid end
function n.Socket:off(m,f)local w=self.handlers[m]if not w then return end;for y=1,#w do if w[y].hid==f then
table.remove(w,y)break end end end
local c=r{function(m,f)h.debug("BSocket Connection:",f.uid)
m(n.Socket.new(f))end}function n.listen(m,f)u.listen(d.bind(c,f),m)end;function n.connect(m)return
u.connect(m):next(n.Socket.new)end;return n end
a["shared.socket.backends.modem"]=function(...)local n={}local s=i("vendor.json")
local h=i("vendor.uuid")local r=i("shared.gcm")local d=i("shared.async")
local l=i("shared.logger")local u=i("shared.tableutils")local c=i("shared.coroutines")
local m=i("shared.socket.types")local f=14762;local w
n.ModemError={UID_TAKEN={id=1,description="UID already taken, please use another"},INVALID_OPTS={id=2,description="Connection options are invalid"}}local y=n.ModemError;n.ModemSocketStatus={CONNECTING=1,READY=2,DEAD=3}
local p=n.ModemSocketStatus;local v={}
function v.new(g,k,q)
local j={uid=g,port=k,type=q,status=p.CONNECTING,handlers={},last_active=os.clock()}
setmetatable(j,{__index=v,__tostring=v.tostring})j:spawnListener()return j end;function v:tostring()
return"MSock<"..tostring(self.uid)..">"end;function v:write(g)
w.transmit(self.port,self.port,s.encode({type="data",uid=self.uid,port=self.port,data=g}))end;function v:ping()
l.trace("Transmitting on port",self.port)
w.transmit(self.port,self.port,s.encode({type="ping",uid=self.uid,port=self.port}))end;function v:onRecieve(g)
table.insert(self.handlers,g)end
function v:onDisconnect(g)self.dcHandler=g end
function v:spawnListener()
r:addRoutine(function()self.status=p.READY
while true do
local g,k=u.postpack(1,coroutine.yield("modem_message_data"))
if g=="modem_message_data"then local q=u.unpack(k)
if
q.type=="data"and q.uid==self.uid and type(q.data)=="table"then
self.last_active=os.clock()l.debug("MSocket",self.uid,"received:",q)if
#self.handlers==0 then
l.warn("Discarding unhandled modem message.")end;for j=1,#self.handlers do
self.handlers[j](q.data)end elseif q.type=="ping"then
l.trace("Recieved ping, sending pong!")
w.transmit(self.port,self.port,s.encode({type="pong",uid=self.uid,port=self.port}))elseif q.type=="pong"and q.uid==self.uid then
self.last_active=os.clock()l.trace("Recieved pong from",self.uid)end end end end)end
function n.tryInit()if not peripheral then return end
w=peripheral.find("modem")if w then
l.debug("Using ".. (w.isWireless()and"wireless"or"")..
" modem for socket backend")return true end end
function n.listen(g,k)k=k or{}local q=k.port or f;w.open(q)
l.debug("Modem backend opened port "..
q.." for connections")local j={}local x={}
local function z(E)local T=x[E.port]if not T then
l.error("Socket was never inserted into portmap?")return end
if E.dcHandler then E:dcHandler()end
for A=1,#T do if T[A]==E.uid then table.remove(T,A)end end;if#T==0 then l.debug("Closing port "..E.port)
w.close(E.port)x[E.port]=nil end end
local function _(E,T)if k.service~=E.service then return end
l.debug("Attempted connection on port "..T.." by "..
tostring(E.uid))
if type(E.uid)~="string"and type(E.port)~="number"then return
w.transmit(T,65535,s.encode({type="connect",uid=E.uid,ok=false,error=y.INVALID_OPTS}))end
if j[E.uid]then
l.debug("Connector tried to take existing uid")return
w.transmit(T,65535,s.encode({type="connect",uid=E.uid,ok=false,error=y.UID_TAKEN}))end
j[E.uid]=v.new(E.uid,E.port,m.SocketType.COMPANION)if not x[E.port]then l.debug("Opening port "..E.port)
w.open(E.port)x[E.port]={}end
table.insert(x[E.port],E.uid)g(j[E.uid])return
w.transmit(E.port,E.port,s.encode({type="connect",uid=E.uid,ok=true}))end
c.loop(function()
while true do c.runTimer(10)
for E,T in pairs(j)do T:ping()if
os.clock()-T.last_active>30 then
l.warn(T," is not responding to pings, dropping...")j[E]=nil;z(T)end end end end,function()
local E=
k.service and("for '"..k.service.."'")or""
l.info("Modem backend now listening on port "..q,E)
while true do
local T,A=u.postpack(1,coroutine.yield("modem_message"))
if T=="modem_message"then local O,O,I,N=u.unpack(A)local S,H=pcall(s.decode,N)
if S and
type(H)=="table"then if H.type=="connect"then _(H,I)else
os.queueEvent("modem_message_data",H)end else
l.debug("Invalid JSON received: '"..N.."'")end end end end)end;local function b()return math.random(1000,9999)end
function n.connect(g)
return
d.Promise.new(function(k,q)g=
g or{}local j=g.port or f;local x=g.selfPort or b()local z=h()
w.open(x)
w.transmit(j,x,s.encode({type="connect",uid=z,port=x,service=g.service}))
r:addRoutine(function()
while true do
local _,E=u.postpack(1,coroutine.yield("modem_message"))
if _=="modem_message"then local T,T,T,A=u.unpack(E)local O,I=pcall(s.decode,A)
if O and
type(I)=="table"then l.trace("Modem message:",I)
if
I.type=="connect"and I.uid==z then
if I.ok then
if g.service then
l.info("Established connection to '"..g.service.."' as",z)else l.info("Connection established!")end;k(v.new(z,x,m.SocketType.INITIATOR))else
l.error("Error establishing connection:",I.error)q(I.error)end else os.queueEvent("modem_message_data",I)end else
l.debug("Invalid JSON received: '"..A.."'")end end end end)end)end;return n end
a["shared.pretty"]=function(...)local n={}
local s={keyword=colors.purple,specialKeyword=colors.lightBlue,func=colors.cyan,string=colors.red,stringEscape=colors.yellow,primitive=colors.orange,comment=colors.lightGray,cref=colors.lightGray,catch=colors.white}
local h={["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,["end"]=true,["false"]=true,["for"]=true,["function"]=true,["if"]=true,["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,["until"]=true,["while"]=true}local r
local function d(p,v)if v~=r then term.setTextColor(v)r=v end;write(p)end
local function l(p,v)local b,g=type(p),type(v)if b=="string"then return g~="string"or p<v elseif
g=="string"then return false end;if b=="number"then return
g~="number"or p<v end;return false end
local u=(
type(debug)=="table"and type(debug.getinfo)=="function"and debug.getinfo)
local function c(p)
if u then local v={}local b=debug.gethook()
local g=function()local k=u(3)
if k.name~="pcall"then return end
for q=1,math.huge do local j=debug.getlocal(2,q)if j=="(*temporary)"or not j then
debug.sethook(b)return error()end;v[#v+1]=j end end;debug.sethook(g,"c")pcall(p)return v end end
local function m(p)
if u then local v=u(p,"S")
if
v.short_src and v.linedefined and v.linedefined>=1 then local b;if v.what=="Lua"then b=c(p)end
if b then
return"function<"..v.short_src..
":"..v.linedefined..">("..
table.concat(b,", ")..")"else return
"function<"..v.short_src..":"..v.linedefined..">"end end end;return tostring(p)end
local function f(p,v,b)local g=type(p)
if g=="string"then return#
string.format("%q",p):gsub("\\\n","\\n")elseif g=="function"then return#m(p)elseif
g~="table"or v[p]then return#tostring(p)end;local k=2;v[p]=true;for q,j in pairs(p)do k=k+f(q,v,b)+f(j,v,b)
if k>=b then break end end;v[p]=nil;return k end
local function w(p,v,b,g,k,q)local j=type(p)
if j=="string"then
local U=string.format("%q",p):gsub("\\\n","\\n")local C=math.max(8,math.floor(b*g*0.8))
if#U>C then
d(U:sub(1,C-3),s.string)d("...",s.string)else d(U,s.string)end;return elseif j=="number"then return d(tostring(p),s.primitive)elseif j=="boolean"then return
d(tostring(p),s.primitive)elseif j=="function"then return d(m(p),s.func)elseif j~="table"or v[p]then return
d(tostring(p),s.cref)elseif(getmetatable(p)or{}).__tostring then return
d(tostring(p),s.catch)end;local x,z="{","}"if q then x,z="(",")"end;if
(q==nil or q==0)and next(p)==nil then return d(x..z,s.catch)elseif b<=7 then d(x,s.catch)d(" ... ",s.cref)
d(z,s.catch)return end
local _=false;local E=q or#p;local T,A,O,I=2,0,{},0
for U,C in pairs(p)do
if
type(U)=="number"and U>=1 and U<=E and U%1 ==0 then local M=f(C,v,b)T=T+M+2;A=A+1 else I=I+1;O[I]=U
local M,F=f(C,v,b),f(U,v,b)T=T+M+F+2;A=A+2 end;if T>=b*0.6 then _=true end end
if _ and g<=1 then d(x,s.catch)d(" ... ",s.cref)d(z,s.catch)return end;table.sort(O,l)local N,S,H,R
if _ then N,S=",\n",k.." "g=g-2
H,R=b-2,math.ceil(g/A)if A>g then A=g-2 end else N,S=", ",""b=b-2;H,R=math.ceil(b/A),1 end;d(x.. (_ and"\n"or" "),s.catch)
v[p]=true;local D={}local L=true
for U=1,E do if not L then d(N,s.catch)else L=false end
d(S,s.catch)D[U]=true;w(p[U],v,H,R,S)A=A-1;if A<0 then
if not L then d(N,s.catch)else L=false end;d(S.."...",s.cref)break end end
for U=1,I do local C,M=O[U],p[O[U]]
if not D[C]then
if not L then d(N,s.catch)else L=false end;d(S,s.catch)
if type(C)=="string"and not h[C]and
C:match("^[%a_][%a%d_]*$")then d(C.." = ",s.catch)w(M,v,H,R,S)else
d("[",s.catch)w(C,v,H,R,S)d("] = ",s.catch)w(M,v,H,R,S)end;A=A-1
if A<0 then if not L then d(N,s.catch)end;d(S.."...",s.cref)break end end end;v[p]=nil
d((_ and"\n"..k or" ").. (q and")"or"}"),s.catch)end
local function y(p,v)local b,g=term.getSize()w(p,{},b,g-2,"",v)end;function n.write(...)local p=select("#",...)
if p>1 then y({...},p)else local v=(...)y(v)end end;function n.print(...)n.write(...)
print()end;return n end
a["shared.logger"]=function(...)local n=_G.LOG_LEVEL or"info"local s={}
s.LogLevels={"off",OFF="off","fatal",FATAL="fatal","error",ERROR="error","warn",WARN="warn","info",INFO="info","debug",DEBUG="debug","trace",TRACE="trace",ALL="all"}local h
function s.init(l,u)l=l or{}u=u or{}if h then
error("Logger already initialized. Use logger.destroy() to reset.",2)end
for f=1,#l do local w=l[f]
for y,p in ipairs(s.LogLevels)do
if
not w[p]and not w.generic then
error("Backend #"..
f.." ("..
tostring(w)..") does"..
" not implement '"..p.."' and does not provide a"..
" generic logger method.")end end end;local c=u.level or n;local m={}
for f,w in ipairs(s.LogLevels)do m[w]=true;if w==c then break end end;h={backends=l,options=u,enabledLevels=m}end
function s.destroy()for l=1,#h.backends do local u=h.backends[l]
if u.destroy then u:destroy()end end;h=nil end
local function r(l)if not h then
error("Logger not initialized, use logger.init first",4)end
if not h.enabledLevels[l]then return false end;return true end
local function d(l,u)if not r(l)then return end;for c,m in ipairs(h.backends)do if m[l]then m[l](m,u)else
m:generic(l,u)end end end;function s.fatal(...)d("fatal",{...})end;function s.error(...)
d("error",{...})end;function s.warn(...)d("warn",{...})end;function s.info(...)
d("info",{...})end;function s.debug(...)d("debug",{...})end;function s.trace(...)
d("trace",{...})end;return s end
a["shared.logger.backends.file"]=function(...)local n={}local s=i("vendor.serpent")
function n.new(h)
local r={handle=fs.open(h,"a")}return setmetatable(r,{__index=n})end
function n:generic(h,r)
local d=("[%s] [%s]"):format(tostring(os.epoch("utc")),h:upper())
for l=1,#r do d=d.." "local u=r[l]
if type(u)=="string"then d=d..u elseif
(getmetatable(u)or{}).__tostring then d=d..tostring(u)else d=d..s.block(u)end end;self.handle.write(d.."\n")
self.handle.flush()end;function n:destroy()self.handle.close()end;return n end
a["shared.logger.backends.console"]=function(...)local n={}
local s=i("shared.stringutils")local h=i("shared.tableutils")local r=i("shared.pretty")function n.new()local c={}return
setmetatable(c,{__index=n})end;local function d(m)if term.isColor()then
term.setBackgroundColor(m)end end
local function l(m)if
term.isColor()then term.setTextColor(m)end end
local function u(c,...)local m=s.explode("%%.",c)local f={...}
for w,y in ipairs(m)do
if y:match("^%%.$")then
local p=y:sub(2)
if p=="B"then d(table.remove(f,1))elseif p=="C"then
l(table.remove(f,1))elseif p=="R"then d(colors.black)l(colors.white)elseif p=="s"then
local v=table.remove(f,1)if type(v)=="string"then write(v)else r.write(v)end elseif p=="v"then
local v=table.remove(f,1)local b=#v
for g=1,b do local k=v[g]
if type(k)=="string"then write(k)else r.write(k)end;if g~=b then write(" ")end end end else write(y)end end;print()end;function n:generic(c,m)
u("%C[%s] %R%v",colors.lightGray,c:upper(),m)end;function n:trace(c)
u("%C[TRACE] %R%C%v",colors.gray,colors.lightGray,c)end;function n:debug(c)
u("%C[DEBUG] %R%v",colors.purple,c)end;function n:info(c)
u("%C[INFO] %R%v",colors.cyan,c)end;function n:warn(c)
u("%C[WARN] %R%v",colors.yellow,c)end;function n:error(c)
u("%C[ERROR] %R%v",colors.red,c)end;function n:fatal(c)
u("%B%C[FATAL]%R %C%v\n",colors.red,colors.white,colors.red,c)end;return n end
a["shared.gcm"]=function(...)local n=i("shared.coroutines").Manager;return
n.new()end
a["shared.funcutils"]=function(...)local n={}local s=i("shared.tableutils")
function n.bind(h,...)
local r=select("#",...)local d={...}
return
function(...)local l=select("#",...)local u={...}local c={}
for m=1,r do c[m]=d[m]end;for m=1,l do c[m+r]=u[m]end;return h(s.unpack(c,1,r+l))end end;return n end
a["shared.encrypt"]=function(...)local n={}local s=i("shared.bit64")
local h={0xffffffc5,0xffffffad,0xffffffa1,0xffffff4d,0xffffff43,0xfffffeff,0xfffffee9,0xfffffebd,0xfffffe9f,0xfffffe95,0xfffffe57,0xfffffe3b,0xfffffe09,0xfffffd19,0xfffffcc7,0xfffffcb5,0xfffffcb3,0xfffffc7f,0xfffffc7d,0xfffffc59,0xfffffc4f,0xfffffc01,0xfffffbff,0xfffffbcb,0xfffffbc9,0xfffffb2d,0xfffffb05,0xfffffad5,0xfffffa9d,0xfffffa43,0xfffffa3d,0xfffffa31,0xfffffa1f,0xfffffa13,0xfffff9df,0xfffff9d1,0xfffff9b9,0xfffff97f,0xfffff925,0xfffff8f9,0xfffff8f3,0xfffff8d1,0xfffff8bd,0xfffff8a5,0xfffff863,0xfffff835,0xfffff82d,0xfffff80f,0xfffff803,0xfffff7cf,0xfffff7ab,0xfffff781,0xfffff733,0xfffff713,0xfffff70f,0xfffff6fb,0xfffff6b5,0xfffff661,0xfffff643,0xfffff60b,0xfffff605,0xfffff5db,0xfffff5b7,0xfffff563,0xfffff557,0xfffff53b,0xfffff52f,0xfffff509,0xfffff49f,0xfffff437,0xfffff42b,0xfffff40d,0xfffff3df,0xfffff3d7,0xfffff3d1,0xfffff3c1,0xfffff36d,0xfffff367,0xfffff35b,0xfffff341,0xfffff33d,0xfffff2ff,0xfffff2ef,0xfffff2cf,0xfffff2a1,0xfffff257,0xfffff229,0xfffff215,0xfffff12d,0xfffff115,0xfffff101,0xfffff0d3,0xfffff0bb,0xfffff095,0xfffff089,0xfffff011,0xfffff001,0xffffefe1,0xffffefd1,0xffffefcf,0xffffef6b,0xffffef5d,0xffffef35,0xffffef27,0xffffee6d,0xffffee4f,0xffffedfb,0xffffed91,0xffffed7f,0xffffed79,0xffffed59,0xffffecf3,0xffffece9,0xffffeca1,0xffffec93,0xffffec69,0xffffec41,0xffffec2d,0xffffebfd,0xffffebbd,0xffffeba9,0xffffeb97,0xffffeb7b,0xffffeb61,0xffffeb5d,0xffffeb31,0xffffeb1f,0xffffeb0d,0xffffeb07,0xffffea6d,0xffffea5f,0xffffea2b,0xffffe9e1,0xffffe9b7,0xffffe98f,0xffffe959,0xffffe951,0xffffe933,0xffffe90f,0xffffe8e1,0xffffe8d9,0xffffe8cd,0xffffe8c9,0xffffe8bd,0xffffe869,0xffffe83d,0xffffe7cd,0xffffe711,0xffffe70d,0xffffe6d1,0xffffe695,0xffffe5f3,0xffffe5ed,0xffffe587,0xffffe50d,0xffffe4fb,0xffffe4b9,0xffffe4b3,0xffffe4af,0xffffe48f,0xffffe485,0xffffe47d,0xffffe45b,0xffffe401,0xffffe3cf,0xffffe357,0xffffe34d,0xffffe31d,0xffffe267,0xffffe243,0xffffe201,0xffffe1ef,0xffffe1e9,0xffffe1dd,0xffffe17f,0xffffe147,0xffffe113,0xffffe0d7,0xffffe095,0xffffe027,0xffffdf8d,0xffffdf81,0xffffdf5b,0xffffdf37,0xffffdf13,0xffffdef7,0xffffded7,0xffffdecd,0xffffde9d,0xffffde73,0xffffde4f,0xffffde4d,0xffffde2f,0xffffde29,0xffffde19,0xffffdde1,0xffffddd5,0xffffddc5,0xffffdd89,0xffffdd5f,0xffffdd3f,0xffffdd39,0xffffdce5,0xffffdcb7,0xffffdc99,0xffffdc7f,0xffffdc63,0xffffdc43,0xffffdc3f,0xffffdc2b,0xffffdb73,0xffffda05,0xffffd9db,0xffffd9b5,0xffffd997,0xffffd979,0xffffd973,0xffffd8f5,0xffffd8a3,0xffffd88f,0xffffd871,0xffffd853,0xffffd823,0xffffd789,0xffffd759,0xffffd753,0xffffd733,0xffffd6ff,0xffffd6f9,0xffffd6cd,0xffffd681,0xffffd657,0xffffd631,0xffffd62b,0xffffd5b9,0xffffd591,0xffffd573,0xffffd565,0xffffd529,0xffffd475,0xffffd463,0xffffd459,0xffffd447,0xffffd433,0xffffd405,0xffffd3c3,0xffffd3b7,0xffffd397,0xffffd36f,0xffffd369,0xffffd2fd,0xffffd2df,0xffffd2d1,0xffffd2ad,0xffffd261,0xffffd21f,0xffffd1ff,0xffffd169,0xffffd163,0xffffd11b,0xffffd109,0xffffd0df,0xffffd0af,0xffffd05d,0xffffd04b,0xffffd021,0xffffd009,0xffffcf9d,0xffffcf37,0xffffcf25,0xffffced7,0xffffcec9,0xffffcec3,0xffffce7d,0xffffce4d,0xffffce03,0xffffcdd5,0xffffcdbb,0xffffcda3,0xffffcd75,0xffffcd3d,0xffffcd07,0xffffccc5,0xffffcc9b,0xffffcc91,0xffffcc8b,0xffffcc85,0xffffcc59,0xffffcc2b,0xffffcc0d,0xffffcbe1,0xffffcb87,0xffffcb83,0xffffcb4b,0xffffcb35,0xffffcae7,0xffffca75,0xffffca4f,0xffffca3d,0xffffca39,0xffffca31,0xffffca2d,0xffffca1f,0xffffca01,0xffffc9e3,0xffffc9bb,0xffffc989,0xffffc961,0xffffc935,0xffffc8db,0xffffc8b1,0xffffc8a7,0xffffc881,0xffffc833,0xffffc7e5,0xffffc7d9,0xffffc7cf,0xffffc7c3,0xffffc781,0xffffc769,0xffffc757,0xffffc755,0xffffc713,0xffffc6e5,0xffffc6c7,0xffffc65f,0xffffc623,0xffffc5d7,0xffffc5cf,0xffffc5c3,0xffffc577,0xffffc541,0xffffc4fd,0xffffc4eb,0xffffc4d5,0xffffc4cf,0xffffc4ab,0xffffc491,0xffffc449,0xffffc403,0xffffc3bf,0xffffc3a1,0xffffc39d,0xffffc349,0xffffc347,0xffffc227,0xffffc221,0xffffc1fd,0xffffc1df,0xffffc185,0xffffc173,0xffffc163,0xffffc137,0xffffc12b,0xffffc0f1,0xffffc0ef,0xffffc0e5,0xffffc0b9,0xffffc0a7,0xffffc07f,0xffffc023,0xffffc007,0xffffc005,0xffffbf89}
local r={0x3,0x5,0x7,0xb,0xd,0x11,0x13,0x17,0x1d,0x1f,0x25,0x29,0x2b,0x2f,0x35,0x3b,0x3d,0x43,0x47,0x49,0x4f,0x53,0x59,0x61,0x65,0x67,0x6b,0x6d,0x71,0x7f,0x83,0x89,0x8b,0x95,0x97,0x9d,0xa3,0xa7,0xad,0xb3,0xb5,0xbf,0xc1,0xc5,0xc7,0xd3,0xdf,0xe3,0xe5,0xe9,0xef,0xf1,0xfb,0x101,0x107,0x10d,0x10f,0x115,0x119,0x11b,0x125,0x133,0x137,0x139,0x13d,0x14b,0x151,0x15b,0x15d,0x161,0x167,0x16f,0x175}function n.generatePartialSecret()end;function n.performHandshake(d)end;return n end
a["shared.coroutines"]=function(...)local n={}local s=i("shared.tableutils")
local h=i("shared.logger")local function r(d)if not d then return true end
return coroutine.status(d)=="dead"end;n.Manager={}
function n.Manager.new()
local d={routines={},garbage={},running=false,id_counter=0}return setmetatable(d,{__index=n.Manager})end
function n.Manager:addRoutine(d,...)
self.id_counter=(self.id_counter+1)%2^32
local l=setmetatable({id=self.id_counter,constructor=d,thread=coroutine.create(d)},{__tostring=function(m)return

tostring(m.thread).."<"..tostring(m.constructor)..">"end})h.trace("Priming "..tostring(l))
local u,c=coroutine.resume(l.thread,...)
if u then if coroutine.status(l.thread)=="suspended"then l.filter=c
table.insert(self.routines,l)end
h.trace("Primed "..tostring(l))return self.id_counter else
h.fatal("Error priming "..tostring(l)..": "..c)return false end end
function n.Manager:killRoutine(d)
h.trace("Thread "..tostring(d).." marked for culling")table.insert(self.garbage,d)end
function n.Manager:shutdown()self.running=false;coroutine.yield()end
function n.Manager:run(d,l)self.running=true;self:addRoutine(i,d)
while self.running and#
self.routines>0 do
local u={coroutine.yield()}
if u[1]=="terminate"then if not l then self.running=false;break end end;self.garbage={}
for c=1,#self.routines do local m=self.routines[c]
if r(m.thread)then
h.trace(
"Marking "..tostring(m).." for collection")table.insert(self.garbage,m.id)else
if
m.filter==u[1]or not m.filter then local f,w=coroutine.resume(m.thread,s.unpack(u))if not
self.running then break end
if f then
if type(w)=="string"then m.filter=w else m.filter=nil end else h.error("Error resuming coroutine: "..w)
h.trace(
"Marking "..tostring(m).." for collection")table.insert(self.garbage,m.id)end end end end
for c=1,#self.garbage do
for m=1,#self.routines do local f=self.routines[m]
if f.id==
self.garbage[c]then
h.trace("Collecting",self.routines[m])table.remove(self.routines,m)break end end end end;h.info("Coroutine manager shutting down...")end
function n.loop(...)local d=select("#",...)local l={...}local u={}local c={}local m=true
while true do local f;if m then m=false else
f={coroutine.yield()}end;if f and f[1]=="terminate"then break end
for w=1,d
do local y=true
if r(u[w])then u[w]=coroutine.create(l[w])
y,c[w]=coroutine.resume(u[w])else if c[w]==f[1]or not c[w]then
y,c[w]=coroutine.resume(u[w],s.unpack(f))end end;if not y then
h.error("Error resuming coroutine: "..c[w])c[w]=nil end end end end;function n.runTimer(d)local l=os.startTimer(d)
while true do
local u,c=coroutine.yield("timer")if u=="timer"and c==l then return end end end;return n end
a["shared.bit64"]=function(...)local n={}local s=bit or bit32 or i("bit32")local h=
s.lshift or s.blshift;local r=s.blogic_rshift or s.rshift;local d=
s.arshift or s.rshift or s.brshift
local l,u,c,m=s.bnot,s.band,s.bor,s.bxor
if jit then local R=i("ffi")
local function D(L)return function(...)
return tonumber(R.cast("uint32_t",L(...)))end end;h=D(h)r=D(r)d=D(d)l,u=D(l),D(u)c,m=D(c),D(m)end;local f=0x7FFFFFFF;local w=0xFFFFFFFF;local y=0xFFFF0000;local p=0x0000FFFF;local v=0x100000000
local b=0x80000000;local g={0,0}local k={1,0}local q={0xFFFFFFFF,0xFFFFFFFF}local j=math.floor
local x=math.ceil;local z,_,E=math.min,math.max,math.abs;local T=table.unpack or unpack;local function A(R,...)
local D={...}R=R or 8
print((("%%0%dX "):format(R)):rep(#D):format(...))end
function n.newInt(R,D)R,D=R or 0,D or 0
assert(R>=
0 and D>=0,"newInt cannot be called with negative components, use :arInverse()")local L={R,D}return setmetatable(L,n)end;function n.copy(R)return n.newInt(R[1],R[2])end;n.clone=n.copy
function n.fromBytes(R,D,L,U,C,M,F,W)return
n.newInt(
R+h(D,8)+h(L,16)+h(U,24),C+h(M,8)+h(F,16)+h(W,24))end;function n.fromBytesBE(...)local R={...}for D=1,4 do R[D],R[9-D]=R[9-D],R[D]end;return
n.fromBytes(T(R))end
function n:plus(R)
local D,L=self[1],self[2]local U,C=R[1],R[2]local M,F=D+U,L+C;if M>w then M=M-v;F=F+1 end;if F>w then F=F-v end;return M,
F end
function n:minus(R)return self:plus({n.unaryMinus(R)})end
local function O(R,D)local L,U=u(R,p),r(u(R,y),16)local C,M=u(D,p),r(u(D,y),16)
local F=n.newInt(0,U*M)local W=L*M+U*C;local Y=u(p,W)local P=h(Y,16)local V=r((W-Y)/2,15)
local B=n.newInt(P,V)local G=n.newInt(L*C,0)return F:add(B):plus(G)end
function n:times(R)local D,L=self[1],self[2]local U,C=R[1],R[2]local M=n.newInt(O(D,U))
local F=n.newInt(O(L,U))local W=n.newInt(O(D,C))local Y=n.newInt(0,(F:plus(W)))return
M:plus(Y)end;local I=32;local N=64
function n:dividedByU(R)local D=self;local L=n.newInt()local U=n.newInt()
local C,M=D[1]or 0,D[2]or 0;local F,W=R[1]or 0,R[2]or 0;local Y=0;if M==0 then
if W==0 then if F==0 then
error("Integer divide by zero")end;return j(C/F),0,C%F,0 end;return 0,0,C,0 end
if F==0 then if W==0 then
error("Integer divide by zero")end;if C==0 then return j(M/W),0,0,M%W end
if
u(W,W-1)==0 then return r(M,n.countTrailingZeros({W})),0,C,u(M,W-1)end
Y=n.countLeadingZeros({W})-n.countLeadingZeros({M})if Y<0 then return 0,0,C,M end;Y=Y+1;L[1]=0;L[2]=h(C,I-Y)U[2]=r(M,Y)
U[1]=c(h(M,I-Y),r(C,Y))else
if W==0 then
if u(F,F-1)==0 then if F==1 then return C,M,u(C,F-1),0 end
Y=n.countTrailingZeros({F})return c(h(M,I-Y),r(C,Y)),r(M,Y),u(C,F-1),0 end
Y=1+I+n.countLeadingZeros({F})-n.countLeadingZeros({M})
if Y==I then L[1]=0;L[2]=C;U[2]=0;U[1]=M elseif Y<I then L[1]=0;L[2]=h(C,I-Y)U[2]=r(M,Y)
U[1]=c(h(M,I-Y),r(C,Y))else L[1]=h(C,N-Y)L[2]=c(h(M,N-Y),r(C,Y-I))U[2]=0
U[1]=r(M,Y-I)end else
Y=n.countLeadingZeros({W})-n.countLeadingZeros({M})if Y<0 then return 0,0,C,M end;Y=Y+1;L[1]=0
if Y==I then L[2]=C;U[2]=0;U[1]=M else
L[2]=h(C,I-Y)U[2]=r(M,Y)U[1]=c(h(M,I-Y),r(C,Y))end end end;local P=0
while Y>0 do U[2]=c(h(U[2],1),r(U[1],I-1))
U[1]=c(h(U[1],1),r(L[2],I-1))L[2]=c(h(L[2],1),r(L[1],I-1))
L[1]=c(h(L[1],1),P)
local V=n.newInt(n.minus(R,U)):sub(k):shr_s({N-1})P=u(V[1],1)U:sub({n.band(R,V)})Y=Y-1 end;L:shl({1})L[1]=c(L[1],P)return L[1],L[2],U[1],U[2]end
function n:dividedByS(R)print("WHYYY")print(debug.traceback())local D=n.copy(
n.isNegative(self)and q or g)local L=n.copy(
n.isNegative(R)and q or g)
local U=n.newInt(n.bxor(self,D)):sub(D)local C=n.newInt(n.bxor(R,L)):sub(L)
D:bxored(L)local M=n.newInt(U:dividedByU(C))return
M:bxored(D):minus(D)end
function n:modU(R)local D,D,L,U=n.dividedByU(self,R)return L,U end;function n:modS(R)local D={n.dividedByS(self,R)}return
self:minus({R:times(D)})end
function n:raiseTo(R)local D=self
local L=n.copy(k)R=n.copy(R)
while true do if R:band(k)~=0 then L:mult(D)end
R:shr_u(k)if R:eqz()==1 then break end;D:mult(D)end;return L[1],L[2]end
function n:lshift(R)local D,L=self[1],self[2]if D==0 and L==0 then return 0,0 end
R=u(R[1],0x3F)if R==0 then return D,L end;if R>=32 then return 0,h(D,R-32)end
local U=r(D,I-R)return h(D,R),h(L,R)+U end
function n:rshift(R)local D,L=self[1],self[2]if D==0 and L==0 then return 0,0 end
R=u(R[1],0x3F)if R==0 then return D,L end;if R>=32 then return r(L,R-32),0 end
local U=h(L,I-R)return r(D,R)+U,r(L,R)end
function n:arshift(R)local D,L=self[1],self[2]if D==0 and L==0 then return 0,0 end
R=u(R[1],0x3F)if R==0 then return D,L end
if R>=32 then return d(L,R-32),d(d(L,31),1)end;local U=h(L,I-R)local C=d(L,z(31,R))local M=r(D,R)+U;if C==w then
M=c(M,d(b,R-33))end;return M,C end
function n:rotateLeft(R)local D,L=self[1],self[2]or 0;R=u(R,0x3F)if R==0 then return D,L end
if
R>32 then return n.rotateRight(self,64-R)elseif R==32 then return L,D end;local U=d(b,R)local C=u(w,h(D,R))local M=r(u(U,L),32-R)local F=c(C,M)
local W=u(w,h(L,R))local Y=r(u(U,D),32-R)local P=c(W,Y)return F,P end
function n:rotateRight(R)local D,L=self[1],self[2]or 0;R=u(R,0x3F)
if R==0 then return D,L end
if R>32 then return n.rotateLeft(self,64-R)elseif R==32 then return L,D end;local U=r(d(b,R),32-R)local C=h(u(U,L),32-R)local M=r(D,R)
local F=c(C,M)local W=h(u(U,D),32-R)local Y=r(L,R)local P=c(W,Y)return F,P end
function n:band(R)local D,L=self[1],self[2]or 0;return u(D,R[1]),u(L,R[2]or 0)end
function n:bor(R)local D,L=self[1],self[2]or 0;return c(D,R[1]),c(L,R[2]or 0)end
function n:bxor(R)local D,L=self[1],self[2]or 0;return m(D,R[1]),m(L,R[2]or 0)end
function n.modexp(R,D,L)if D:equals({0})then return 1 end
local U=n.newInt(D:dividedByU({2,0}))local C=n.newInt(n.modexp(R,U,L))
if
n.equals({D:modU({2})},{0})then return n.modU({C:times(C)},L)else return
n.modU({R:times({C:times(C)})},L)end end
function n:countLeadingZeros()local R,D=self[1],self[2]or 0
if R==0 and D==0 then return 64 end;local L=0;if D==0 then L=L+32 else R=D end
if u(R,0xFFFF0000)==0 then L=L+16;R=h(R,16)end;if u(R,0xFF000000)==0 then L=L+8;R=h(R,8)end;if
u(R,0xF0000000)==0 then L=L+4;R=h(R,4)end
if u(R,0xC0000000)==0 then L=L+2;R=h(R,2)end;if u(R,0x80000000)==0 then L=L+1 end;return L end
function n:countTrailingZeros()local R,D=self[1],self[2]if R==0 and D==0 then return 64 end
local L=0;if R==0 then L=L+32;R=D end
if u(R,0x0000FFFF)==0 then L=L+16;R=r(R,16)end;if u(R,0x000000FF)==0 then L=L+8;R=r(R,8)end;if
u(R,0x0000000F)==0 then L=L+4;R=r(R,4)end
if u(R,0x00000003)==0 then L=L+2;R=r(R,2)end;if u(R,0x00000001)==0 then L=L+1 end;return L end
local function S(R)local D,L=1,0;while D<=b do if u(R,D)~=0 then L=L+1 end;D=D*2 end;return L end
function n:countSetBits()local R,D=self[1],self[2]return S(R)+S(D)end
function n:sign()local R,D=self[1],self[2]if R==0 and D==0 then return 0 end;if u(D,b)==0 then
return 1 else return-1 end end;function n:unaryMinus()local R=l(self[1])%v;local D=l(self[2]or 0)%v;return
n.plus({R,D},k)end;function n:isPositive()return
n.sign(self)==1 end;function n:isNegative()
return n.sign(self)==-1 end;function n:equals(R)
return(self[1]or 0)== (R[1]or 0)and(
self[2]or 0)== (R[2]or 0)end
function n:eqz()return
(self[1]==0 and self[2]==0)and 1 or 0 end
function n:eq(R)return
(self[1]==R[1]and self[2]==R[2])and 1 or 0 end
function n:ne(R)return
(self[1]~=R[1]or self[2]~=R[2])and 1 or 0 end
function n:lt_s(R)local D,L=n.sign(self),n.sign(R)
if D~=L then return(D<L)and 1 or 0 end;if D==0 then return 0 end;local U=n.sign({n.minus(R,self)})return(
U==1)and 1 or 0 end
function n:lt_u(R)local D,L=self[1],self[2]local U,C=R[1],R[2]local M,F=L==0,C==0;if M and F then return
(D<U)and 1 or 0 end
if M and not F then return 1 elseif F and not M then return 0 end
if L==C then return(D<U)and 1 or 0 else return(L<C)and 1 or 0 end end;function n:le_s(R)return 1-n.lt_s(R,self)end;function n:gt_s(R)
return n.lt_s(R,self)end
function n:ge_s(R)return 1-n.lt_s(self,R)end;function n:le_u(R)return 1-n.lt_u(R,self)end;function n:gt_u(R)
return n.lt_u(R,self)end
function n:ge_u(R)return 1-n.lt_u(self,R)end
function n:signExtend8()
local R=u(self[1],0x80)~=0 and b or 0;return c(u(self[1],0xFF),d(R,23)),d(R,31)end
function n:signExtend16()
local R=u(self[1],0x8000)~=0 and b or 0;return c(u(self[1],0xFFFF),d(R,15)),d(R,31)end;function n:signExtend32()
local R=u(self[1],0x80000000)~=0 and b or 0;return self[1],d(R,31)end;function n:add(R)
self[1],self[2]=self:plus(R)return self end;function n:sub(R)
self[1],self[2]=self:minus(R)return self end;function n:mult(R)
self[1],self[2]=self:times(R)return self end;function n:div_u(R)
self[1],self[2]=self:dividedByU(R)return self end;function n:div_s(R)
self[1],self[2]=self:dividedByS(R)return self end;function n:rem_u(R)
self[1],self[2]=self:modU(R)return self end;function n:rem_s(R)
self[1],self[2]=self:modS(R)return self end;function n:shl(R)
self[1],self[2]=self:lshift(R)return self end;function n:shr_u(R)
self[1],self[2]=self:rshift(R)return self end;function n:shr_s(R)
self[1],self[2]=self:arshift(R)return self end;function n:ctz(R)
self[1],self[2]=self:countTrailingZeros(R),0;return self end;function n:clz(R)
self[1],self[2]=self:countLeadingZeros(R),0;return self end;function n:popcnt()
self[1],self[2]=self:countSetBits(),0;return self end;function n:rotl(R)
self[1],self[2]=self:rotateLeft(R[1])return self end;function n:rotr(R)
self[1],self[2]=self:rotateRight(R[1])return self end;function n:banded(R)
self[1],self[2]=self:band(R)return self end;function n:bored(R)
self[1],self[2]=self:bor(R)return self end;function n:bxored(R)
self[1],self[2]=self:bxor(R)return self end;function n:arInverse()
self[1],self[2]=self:unaryMinus()return self end;function n:extend8_s()
self[1],self[2]=self:signExtend8()return self end;function n:extend16_s()
self[1],self[2]=self:signExtend16()return self end;function n:extend32_s()
self[1],self[2]=self:signExtend32()return self end;function n:__tostring()return
("i64<%08X,%08X>"):format(self[2],self[1])end
local function H(R)return function(...)return
n.newInt(R(...))end end;n.__index=n
n.__call=function(R,...)return n.newInt(...)end;n.__unm=H(n.unaryMinus)n.__add=H(n.plus)n.__sub=H(n.minus)
n.__mul=H(n.times)n.__div=H(n.dividedByS)n.__idiv=H(n.dividedByS)
n.__mod=H(n.modS)n.__pow=H(n.raiseTo)
n.zero=function()return n.copy(g)end;n.one=function()return n.copy(k)end
n.negOne=function()return n.copy(q)end;setmetatable(n,n)return n end
a["shared.async"]=function(...)local n={}local s=i("shared.tableutils")
local h=i("shared.logger")local r=i("shared.gcm")
n.Promise={States={PENDING=1,RESOLVED=2,REJECTED=3,CANCELED=4}}
local function d(l,u)h.trace(tostring(l),": trying to dispatch")if l.yield then if u then
u(s.unpack(l.yield))end end end
function n.Promise.new(l)local u={}u.status=n.Promise.States.PENDING
setmetatable(u,{__index=n.Promise,__tostring=n.Promise.tostring})
local c=function(...)
if u.status~=n.Promise.States.PENDING then return end;u.status=n.Promise.States.RESOLVED;u.yield={...}
d(u,u.waiter)end
local m=function(...)
if u.status~=n.Promise.States.PENDING then return end;u.status=n.Promise.States.REJECTED;u.yield={...}
d(u,u.catcher)
if not u.catcher then h.fatal("Unhandled promise rejection:",...)end end;u.rid=r:addRoutine(l,c,m)return u end
function n.Promise.any(...)local l={...}
return
n.Promise.new(function(u,c)
local function m()for f=1,#l do l[f]:cancel()end end;for f=1,#l do local w=l[f]
w:next(function(...)m()u(...)end):catch(function(...)
m()c(...)end)end end)end
function n.Promise:tostring()if self.status==n.Promise.States.PENDING then
return"Promise<pending>"else
return"Promise<"..tostring(self.yield)..">"end end
function n.Promise:cancel()if self.status==n.Promise.States.PENDING then
self.status=n.Promise.States.CANCELED end end
function n.Promise:next(l)
if self.status==n.Promise.States.RESOLVED then
local u={l(s.unpack(self.yield))}
if select("#",s.unpack(u))>0 then self.yield=u end;return self end
if self.waiter then local u=self.waiter
self.waiter=function(...)local c={u(...)}if
select("#",s.unpack(c))>0 then self.yield=c end;return
l(s.unpack(self.yield))end else self.waiter=l end;return self end
function n.Promise:catch(l)
return
n.Promise.new(function(u,c)self:next(u)
self.catcher=function(...)
local m,f=s.postpack(1,pcall(l,...))if m then u(s.unpack(f))else c(s.unpack(f))end end end)end
function n.Promise:finally(l)return
n.Promise.new(function(u,c)
self:next(function(...)u(...)l(...)end):catch(function(...)
c(...)l(...)end)end)end
function n.await(l)if type(l[1])=="table"then l=l[1]end;if not l.next then
error("await called with non-promise",2)end;local u
l:next(function(...)h.trace(l,": resolved!")
u={...}end)
h.trace("await : about to yield for",tostring(l))while not u do coroutine.yield()end;return s.unpack(u)end
setmetatable(n,{__call=function(l,u)if type(u)=="table"then u=u[1]end;if type(u)~="function"then
error("async generator called with non-function",2)end
return
function(...)local c={...}return
n.Promise.new(function(m,f)
local w,y=s.postpack(1,pcall(u,s.unpack(c)))if w then m(s.unpack(y))else f(s.unpack(y))end end)end end})return n end
a["shared.apierrors"]=function(...)
return
{SVERR={code=-1,description="Internal Server Error"},NINGAME={code=0,description="You are not in a game."},AINGAME={code=1,description="You are already in a game."},INVALIDREQ={code=2,description="Invalid request options."},MISSING=function(n)return{code=3,description=
"Missing parameter '"..n.."'"}end,WTYPE=function(n,s)
return{code=4,description=
"Expected type '"..n.."' for "..s}end,BOUND=function(n,s)return
{code=5,description="Parameter '"..s..
"' out of bounds, expected "..n}end,NEXISTS={code=6,description="Requested entity does not exist"}}end
a["client.wordbar"]=function(...)local n={}function n.new(s)local h={width=s,text="______a_",time=34}
setmetatable(h,{__index=n,__tostring=n.tostring})return h end
function n:render()
local s=term.getSize()term.setBackgroundColor(colors.gray)
term.setTextColor(colors.white)term.setCursorPos(s-self.width+1,1)
term.write((" "):rep(self.width))
local h=math.floor((self.width+#self.text)/2)term.setCursorPos(s-h,1)term.write(self.text)
self:renderTime()end
function n:renderTime()local s=term.getSize()
term.setBackgroundColor(colors.gray)if self.time<=10 then term.setTextColor(colors.red)else
term.setTextColor(colors.white)end
term.setCursorPos(s-self.width+2,1)
term.write(tostring(self.time).."s")end;return n end
a["client.uiutil"]=function(...)local n={}
function n.centerWrite(s,h)local r=term.getSize()local d=0;for u in
h:gmatch("[^\n]+")do d=math.max(d,#u)end
local l=math.ceil((r-d)/2)for u in h:gmatch("[^\n]+")do term.setCursorPos(l,s)term.write(u)
s=s+1 end end;return n end
a["client.toolbar"]=function(...)local n={}n.Tool={PENCIL=1,ERASER=2,FILL=3}
local s={[n.Tool.PENCIL]="pen",[n.Tool.ERASER]="erase",[n.Tool.FILL]="fill"}
local h={[n.Tool.PENCIL]=colors.green,[n.Tool.ERASER]=colors.orange,[n.Tool.FILL]=colors.blue}function n.new(r,d)local l={x=r,y=d,selected=n.Tool.PENCIL}
setmetatable(l,{__index=n,__tostring=n.tostring})return l end
function n:render()
term.setCursorPos(self.x,self.y)
for r=1,#s do
if self.selected==r then term.setBackgroundColor(h[r])
term.setTextColor(colors.white)else term.setBackgroundColor(colors.gray)
term.setTextColor(colors.lightGray)end;term.write(s[r])local d,l=term.getCursorPos()
term.setCursorPos(d+1,l)end end;return n end
a["client.messages"]=function(...)local n={}local s=i("vendor.uuid")
local h=i("shared.gcm")local r=i("shared.async")local d=i("shared.logger")
local l=i("shared.tableutils")local u=i("client.connection")local function c(m)
return u:request("guess",{text=m})end
function n.new(m)
local f={width=m,textField={content="",cursor=0,scrollX=0},pendingMessages={},messages={}}
setmetatable(f,{__index=n,__tostring=n.tostring})h:addRoutine(f.inputThread,f)
u:on("message",function(w)
d.info("Message!",w)table.insert(f.messages,1,w)f:render()end)return f end
function n:inputThread()
while true do local m,f=coroutine.yield()
if m=="char"then
local w=self.textField.cursor;local y=self.textField.content
y=y:sub(1,w)..f..y:sub(w+1)self.textField.content=y;self.textField.cursor=w+1
self:renderTextField()elseif m=="key"then
if f==keys.enter then local w=s()
table.insert(self.pendingMessages,1,{id=w,author={name="Ema",color=colors.lightGray},content={text=self.textField.content,color=colors.lightGray}})
c(self.textField.content):next(function()d.info("is okay")end):catch(function(m)
d.info(debug.traceback())if type(m)=="table"then
m=m.description or m.error or m.err end
table.insert(self.messages,1,{author={name="SERVER",color=colors.orange},content={text=tostring(m),color=colors.red}})end):finally(function()
for y=1,
#self.pendingMessages do if self.pendingMessages[y].id==w then
table.remove(self.pendingMessages,y)break end end;self:render()end)self.textField.content=""self.textField.cursor=0
self:render()end end end end
function n:render()local m=self.width;local f=select(2,term.getSize())local w=m+1
term.setBackgroundColor(colors.lightGray)term.setTextColor(colors.white)for y=1,f do
term.setCursorPos(w,y)term.write("\149")end
term.setBackgroundColor(colors.gray)term.setTextColor(colors.lightGray)for y=1,f do
term.setCursorPos(w+1,y)term.write("\149")end
term.setBackgroundColor(colors.white)term.setTextColor(colors.gray)
for y=1,f do
term.setCursorPos(1,y)term.write((" "):rep(m))end;self:printMessages(m,f-3)self:renderTextField()
self:placeCursor()end
function n:renderTextField()local m=select(2,term.getSize())
term.setCursorPos(1,m-1)term.setBackgroundColor(colors.lightGray)
term.write((" "):rep(self.width))term.setCursorPos(1,m-1)
term.write(self.textField.content)end;function n:placeCursor()local m=select(2,term.getSize())
term.setTextColor(colors.black)term.setCursorPos(1,m-1)
term.setCursorBlink(true)end
function n:printMessages(m,f)
local w,y
local p=l.proxycat(self.pendingMessages,self.messages)w,y=p[1],1
while w and f>=1 do term.setTextColor(w.content.color)
local v=w.content.text;local b=math.ceil(#v/m)for k=1,b do term.setCursorPos(1,f-b+k)
term.write(v:sub(1,m))v=v:sub(m+1)end;f=f-b;local g=p[y+1]
if
(not g)or g.author.name~=w.author.name then
if w.author.name then term.setTextColor(
w.author.color or colors.black)
term.setCursorPos(1,f)term.write(w.author.name or"")f=f-2 else f=f-1 end end;y=y+1;w=p[y]end end;return n end
a["client.main"]=function(...)local n=i("client.connection")
local s=i("shared.logger")local h=i("shared.async")
n:request("joingame",{color=colors.brown,name="Lemmmy",code="UOIG"})
n:request("games"):next(function(g)s.info(g)end)local r,d=term.getSize()local l=i("client.canvas")
local u=l.new(17,1,35,19)u:render()local c=i("client.colorselector")local m=c.new(50,2)
m:render()local f=i("client.wordbar")local w=f.new(35)w:render()
local y=i("client.toolbar")local p=y.new(18,d)p:render()local v=i("client.messages")
local b=v.new(14)b:render()b:placeCursor()while true do os.pullEvent()end end
a["client.gamestate"]=function(...)local n={}function n.reset()end;n.reset()return n end
a["client.connection"]=function(...)local n=i("shared.socket")
local s=i("shared.gcm")local h=i("shared.async")local r=i("client.uiutil")local d
local l=h{function()
term.clear()term.setCursorPos(1,1)term.write("Connecting...")while not
d do os.sleep(0.5)end end}
local u=h{function(m)os.sleep(m)error("Connection timed out")end}
local function c(m)
if type(m)=="table"and m.description then m=m.description end
while true do term.setBackgroundColor(colors.gray)
term.clear()term.setTextColor(colors.white)
r.centerWrite(2,"Error connecting to server")term.setTextColor(colors.red)
r.centerWrite(4,tostring(m))os.sleep(0.5)end end;while not d do
d=h.await{h.Promise.any(l(),u(5),n.connect({service="sccriblio"})):catch(c)}end;return d end
a["client.colorselector"]=function(...)local n={}function n.new()
local s={selected={colors.white,colors.lightBlue}}
setmetatable(s,{__index=n,__tostring=n.tostring})return s end
function n:render()
local s,h=term.getSize()local r=math.ceil((h-16)/2)
for d=1,16 do
term.setCursorPos(s,r+d)local l=2^ (d-1)
if l==self.selected[1]then
term.setBackgroundColor(l)term.setTextColor(colors.lightGray)
term.write("\149")elseif l==self.selected[2]then term.setBackgroundColor(l)
term.setTextColor(colors.gray)term.write("\149")else term.setBackgroundColor(l)
term.write(" ")end end end;return n end
a["client.canvas.instructions"]=function(...)return{CLEAR=1,PIXEL=2,FILL=3}end
a["client.canvas"]=function(...)local n={}local function s(h)return
("%X"):format(math.log(h)/math.log(2))end;function n.new(h,r,d,l)local u={}
setmetatable(u,{__index=n})u:reframe(h,r,d,l)return u end
function n:reframe(h,r,d,l)
self.x,self.y=h,r;self.width,self.height=d,l
self.origin_x=h+math.floor(d/2)self.origin_y=r+math.floor(l/2)
self.instance={bg={},fg={},tx={}}
for u=1,l do self.instance.bg[u]={}
self.instance.fg[u]={}self.instance.tx[u]={}for c=1,d do
self.instance.bg[u][c]=s(colors.gray)self.instance.fg[u][c]=s(colors.black)
self.instance.tx[u][c]="\127"end end end;function n:canvasToInternal(h,r)
return h+math.floor(self.width/2)+1,r+math.floor(
self.height/2)+1 end;function n:scrnToCanvas(h,r)return
h-self.origin_x,r-self.origin_y end
function n:render()
for h=1,self.height
do
local r=table.concat(self.instance.bg[h],"")
local d=table.concat(self.instance.fg[h],"")
local l=table.concat(self.instance.tx[h],"")term.setCursorPos(self.x,self.y+h-1)
term.blit(l,d,r)end end;return n end
a["client.bootstrap"]=function(...)local n=i("shared.logger")
n.init({i("shared.logger.backends.file").new("client.log")},{level=n.LogLevels.ALL})local s=i("shared.gcm")
n.info("Bootstrapping application...")s:run("client.main")n.destroy()end;return a["client.bootstrap"](...)