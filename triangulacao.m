clear all
close all 

%%%%%%%%%% Dados de Entrada %%%%%%%%%%%%%


SNR = 37;                                                   % Relação Sinal Ruído
W = 15.8;                                                    % "Largura" da Gaussiana  
W = W*1.66;                                               % Largura da Gaussiana corrigida
P0 = 1;                                                        % Amplitude da Gaussiana
startP = -30;                                                % Inicio da translação da gaussiana sobre a reta x=y 
endP = 30;                                                  % Fim da translação da gaussiana sobre a reta x=y
step = 1;                                                      % Passo da translação 


%%%%%%%%%% Criaçao da Malha %%%%%%%%%%%%%%

[X,Y] = meshgrid(10*startP:1:10*endP);                         

%%%%%% Movimentar a Gaussiana em uma reta x=y %%%%%%%

dx = startP:step:endP;
dy = startP:step:endP;

%%%%% Gaussiana a ser Deslocada %%%%%%
% Descomentar a linha abaixo só para verificação da Gaussiana, a variável
% PG não é utilizada no código

%PG = P0.*exp(-((dx).^2/(W.^2)));

%%%%%%%%%%% Definição das posições dos fotodetectores %%%%%%%%%%%%%%%%

d = W*sqrt(3/2);                                    % Definição do lado do triângulo equilátero                                
                                         
% Posição do Fotodetector 1

x1 = 0;
y1 = d*(sqrt(3)/3);

% Posição do Fotodetector 2

x2 = -d/2;
y2 = -d*(sqrt(3)/6);

% Posição do Fotodetector 3

x3 = d/2;
y3 = -d*(sqrt(3)/6);

% Medida da Potência nos fotodetectores a medidas que a Gaussiana se move %

for i=1:1:length(dx)
    P1(i) = P0.*exp(-(((x1-dx(i)).^2+(y1-dy(i)).^2)/(W.^2)));
    P2(i) = P0.*exp(-(((x2-dx(i)).^2+(y2-dy(i)).^2)/(W.^2)));
    P3(i) = P0.*exp(-(((x3-dx(i)).^2+(y3-dy(i)).^2)/(W.^2)));
    PC(i) = P0.*exp(-(dx(i).^2+dy(i).^2)/(W.^2));
end

%%%%%%% Adição de ruido gaussiano nas medidas %%%%%%%%

P1N = awgn(P1,SNR,"measured","dB");
P2N = awgn(P2,SNR,"measured","dB");
P3N = awgn(P3,SNR,"measured","dB");

%%%%%%% Solução dos Sistema de Equações %%%%%%%%%%%

out={};
x0 = [-30 -30];
for i=1:length(P1N)
    [solution,x0_novo] = resolve_triang(x0,x1,y1,x2,y2,x3,y3,P1N(i),P2N(i),P3N(i),W);
     x0 = x0_novo;
     out = [out,solution];
end   

for i=1:length(P1N)
     xc(i) = out{i}(1);                    % Coordenada x calculada pelo sistema de equações
     yc(i) = out{i}(2);                    % Coordenada y calculada pelo sistema de equações
end


%%%%%%%%% Saída de Dados %%%%%%%%

for i=1:length(xc)
    dist(i) = sqrt((dx(i)-xc(i)).^2+(dy(i)-yc(i)).^2);      % Cáculo do erro (distância euclidiana)
end

figure("Name", "Deslocamento Calculado")                                       
hold on
grid on
plot(xc,yc,'red')
plot(x1,y1,'o', 'MarkerSize',20)
plot(x2,y2,'o', 'MarkerSize',20)
plot(x3,y3,'o', 'MarkerSize',20)
xlim([startP endP])
xlabel('Deslocamento em x (mm)') 
ylabel('Deslocamento em y (mm)') 

figure ("Name", "Erro")
plot(xc,dist)
grid on
xlim([startP endP])
ylim([0 10])
ylabel('Erro (mm') 
xlabel('Deslocamento da Gaussiana (mm)') 


%%%%%%% Função para resolver o sistema de equações %%%%%%%%%%%%%%%%

function [solution,x0_novo] = resolve_triang(x0,x1,y1,x2,y2,x3,y3,P1,P2,P3,W)
format long
solution={};

AUX=[x1,y1,x2,y2,x3,y3,P1,P2,P3];
f = @(x) resolve_sistema(x,AUX);

options = optimset('Algorithm','levenberg-marquardt',"MaxIter",10000,"TolX",1e-9);
resp= fsolve(f,x0,options);

solution=[solution,resp];
x0_novo=resp;

    function F = resolve_sistema(x,AUX)
               
        F=[ ((((AUX(1)-x(1))^2)) + (((AUX(2)-x(2))^2)) - (W^2)* (-log(AUX(7))))       
            ((((AUX(3)-x(1))^2)) + (((AUX(4)-x(2))^2)) - (W^2)* (-log(AUX(8)))) 
            ((((AUX(5)-x(1))^2)) + (((AUX(6)-x(2))^2)) - (W^2)* (-log(AUX(9))))];
    end

return 

end
