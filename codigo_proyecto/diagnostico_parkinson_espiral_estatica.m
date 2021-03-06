clc;
clear all;

%recoleccion de archivos de entrenamiento
pstore=datastore([pwd '\dataset\new_dataset\parkinson\*.txt']);
cstore=datastore([pwd '\dataset\new_dataset\control\*.txt']);
%aplicacion de funciones de preprocesamiento y extraccion de
%caracteristicas
pstore=transform(pstore,@preprocesamientop);
cstore=transform(cstore,@preprocesamientoc);
caracp=transform(pstore,@extraer);
caracc=transform(cstore,@extraer);
%codigo para graficar uno de los archivos
%prueba2=read(cstore);
%plot(prueba2.x,prueba2.y)
%title("espiral")
%axis equal

%figure;
%subplot(3,1,1)
%plot(prueba2.t,prueba2.x)
%title("x vs t")
%subplot(3,1,2)
%plot(prueba2.t,prueba2.y)
%title("y vs t")
%subplot(3,1,3)
%plot(prueba2.t,prueba2.p)
%title("p vs t")


%organizar todas las caracteristicas y categorizar la columna de enfermos
%que es la que dice si se tiene o no la condicion de Parinson
parkinson=readall(caracc);
control=readall(caracp);
total=[parkinson;control];
total.enfermo=categorical(total.enfermo);

%recoleccion de archivos de prueba
tpstore=datastore([pwd '\dataset\new_dataset\test\parkinson\*.txt']);
tcstore=datastore([pwd '\dataset\new_dataset\test\control\*.txt']);
%aplicacion de funciones de preprocesamiento y extraccion de
%caracteristicas
tpstore=transform(tpstore,@preprocesamientop);
tcstore=transform(tcstore,@preprocesamientoc);
caractp=transform(tpstore,@extraer);
caractc=transform(tcstore,@extraer);
%organizar todas las caracteristicas y categorizar la columna de enfermos
%que es la que dice si se tiene o no la condicion de Parinson
ptest=readall(caractp);
ctest=readall(caractc);
totaltest=[ptest;ctest];
totaltest.enfermo=categorical(totaltest.enfermo);

%ciclo for para realizar la comparacion del sistema con distintos numeros
%de vecinos
for i=2:8
    %generacion del modelo
    mdl4=fitcknn(total,"enfermo","NumNeighbors",i);
    %prueba del modelo
    pred=predict(mdl4,totaltest);
    %medicion de la precision
    result=totaltest.enfermo==pred;
    result=cumsum(result);
    acierto(i-1)=result(end)/numel(result);
    aciertodistribuido(i-1)=1-loss(mdl4,totaltest);
    
    
    %medicion de los falsos negativos
    falsonegarr=(totaltest.enfermo=="si")&(pred=="no");
    trueposarr=(totaltest.enfermo=="si")&(pred=="si");
    falsoneg(i-1)=sum(falsonegarr)/(sum(falsonegarr)+sum(trueposarr));
    %medicion de los falsos positivos
    falsoposarr=(totaltest.enfermo=="no")&(pred=="si");
    truenegarr=(totaltest.enfermo=="no")&(pred=="no");
    falsopos(i-1)=sum(falsoposarr)/(sum(falsoposarr)+sum(truenegarr));

    %sensibilidad
    sens(i-1)=sum(trueposarr)/(sum(trueposarr)+sum(truenegarr));

    %especificidad
    esp(i-1)=sum(truenegarr)/(sum(falsoposarr)+sum(falsonegarr));

    %codigo para la creacion de las tablas de confusion presentadas en el
    %documento
    %figure;
    %confusionchart(totaltest.enfermo,pred)
    %title([string(i) " vecinos"]);
end

%generacion de la tabla comparativa entre los distintos numeros de vecinos
errorarr=[acierto;aciertodistribuido;falsoneg;falsopos;sens;esp]
error=array2table(errorarr,"VariableNames",["2" "3" "4" "5" "6" "7" "8"],"RowNames",["acierto";"acierto_distribuido";"falso negativo";"falso positivo";"sensibilidad"; "especificidad"])





%preprocesamineto para los pacientes con parkinson
function tablafinal = preprocesamientop(tablainicial)
    %se a??aden los nombres de las variables que no vienen en los archivos
    %pero si en el redme del dataset
    tablainicial.Properties.VariableNames= {'x','y','z','p','ang','t','id'};
    %se eliminan los datos de las pruebas que no se van a utilizar
    borrar=tablainicial.id>0;
    tablainicial(borrar,:)=[];
    %se a??ade la columna de clasificacion a la tabla
    clasifiacion=[];
    for i=1:numel(tablainicial.t)
        clasificacion(i)="si";
    end
    clasificacion=clasificacion';
    tablainicial=addvars(tablainicial,clasificacion);
    %se estandariza el tiempo para que todos comienzen en 0
    tf=tablainicial.t(1);
    tablainicial.t=tablainicial.t-tf;
    %se generan las derivadas discretas
    dx=diff(tablainicial.x);
    dx(end+1)=dx(end);
    dy=diff(tablainicial.y);
    dy(end+1)=dy(end);
    dt=diff(tablainicial.t);
    dt(end+1)=dt(end);
    dxy=sqrt(dx.^2.+dy.^2);
    dxdt=dx./dt;
    dydt=dy./dt;
    dxydt=dxy./dt;

    ax=diff(dxdt);
    ax(end+1)=ax(end);
    ax=ax./dt;
    ay=diff(dydt);
    ay(end+1)=ay(end);
    ay=ay./dt;
    axy=diff(dxydt);
    axy(end+1)=axy(end);
    axy=axy./dt;

    jx=diff(ax);
    jx(end+1)=jx(end);
    jx=jx./dt;
    jy=diff(ay);
    jy(end+1)=jy(end);
    jy=jy./dt;
    jxy=diff(axy);
    jxy(end+1)=jxy(end);
    jxy=jxy./dt;

    dpdt=diff(tablainicial.p);
    dpdt(end+1)=dpdt(end);
    dpdt=dpdt./dt;
    %se a??aden las nuevas variables a las tablas creadas
    tablainicial=addvars(tablainicial,dt,dx,dy,dxy,dxdt,dydt,dxydt,ax,ay,axy,jx,jy,jxy,dpdt);
    

    tablafinal=tablainicial;
    
end

%preprocesamiento para los sujetos de control que es igual pero la
%clasificacion cambia de un si a un no
function tablafinal = preprocesamientoc(tablainicial)
    tablainicial.Properties.VariableNames= {'x','y','z','p','ang','t','id'};
    borrar=tablainicial.id>0;
    tablainicial(borrar,:)=[];
    
    clasifiacion=[];
    for i=1:numel(tablainicial.t)
        clasificacion(i)="no";
    
    end
    clasificacion=clasificacion';
    tablainicial=addvars(tablainicial,clasificacion);
    tf=tablainicial.t(1);
    tablainicial.t=tablainicial.t-tf;
    dx=diff(tablainicial.x);
    dx(end+1)=dx(end);
    dy=diff(tablainicial.y);
    dy(end+1)=dy(end);
    dt=diff(tablainicial.t);
    dt(end+1)=dt(end);
    dxy=sqrt(dx.^2.+dy.^2);
    dxdt=dx./dt;
    dydt=dy./dt;
    dxydt=dxy./dt;

    ax=diff(dxdt);
    ax(end+1)=ax(end);
    ax=ax./dt;
    ay=diff(dydt);
    ay(end+1)=ay(end);
    ay=ay./dt;
    axy=diff(dxydt);
    axy(end+1)=axy(end);
    axy=axy./dt;

    jx=diff(ax);
    jx(end+1)=jx(end);
    jx=jx./dt;
    jy=diff(ay);
    jy(end+1)=jy(end);
    jy=jy./dt;
    jxy=diff(axy);
    jxy(end+1)=jxy(end);
    jxy=jxy./dt;

    dpdt=diff(tablainicial.p);
    dpdt(end+1)=dpdt(end);
    dpdt=dpdt./dt;

    tablainicial=addvars(tablainicial,dt,dx,dy,dxy,dxdt,dydt,dxydt,ax,ay,axy,jx,jy,jxy,dpdt);
    tablafinal=tablainicial;
    
end

%funcion de extraccion de variables
function carac = extraer(tablainicial)
    enfermo=tablainicial.clasificacion(1);
    duracion=tablainicial.t(end);
    sdx=std(tablainicial.x);
    sdy=std(tablainicial.y);
    rngx=range(tablainicial.x);
    rngy=range(tablainicial.y);
    promx=mean(tablainicial.x);
    promy=mean(tablainicial.y);
    promdxdt=mean(tablainicial.dxdt);
    promdydt=mean(tablainicial.dydt);
    promdxydt=mean(tablainicial.dxydt);
    sddxdt=std(tablainicial.dxdt);
    sddydt=std(tablainicial.dydt);
    sddxydt=std(tablainicial.dxydt);
    promax=mean(tablainicial.ax);
    promay=mean(tablainicial.ay);
    promaxy=mean(tablainicial.axy);
    promjx=mean(tablainicial.jx);
    promjy=mean(tablainicial.jy);
    promjxy=mean(tablainicial.jxy);
    promp=mean(tablainicial.p);
    promdpdt=mean(tablainicial.dpdt);
    sdp=std(tablainicial.p);

    %se devuelven las caracteristicas extraidas en una tabla
    carac=table(duracion,sdx,sdy,rngx,rngy,promx,promy,promdxdt,promdydt,promdxydt,sddxdt,sddydt,sddxydt,promax,promay,promaxy,promjx,promjy,promjxy,promp,promdpdt,sdp,enfermo);
   
end
