tic;
clear all; close all; clc;

% Parámetros
tamano_grid = 100;
num_flores = 15;
num_abejas = 10;
capacidad_flor = 5;
num_arboles = 9;
tamano_arbol_min = 8;
tamano_arbol_max = 10;
ambiente = zeros(tamano_grid, tamano_grid);

% Panal
centro_x = round(tamano_grid / 2);
centro_y = round(tamano_grid / 2);
ambiente(centro_x - 2:centro_x + 2, centro_y - 2:centro_y + 2) = 2;

miel_panal = 0;

% Generar flores
flores = zeros(tamano_grid, tamano_grid);
for i = 1:num_flores
    while true
        x = randi(tamano_grid);
        y = randi(tamano_grid);

        if ambiente(x, y) == 0 && norm([x - centro_x, y - centro_y]) > 15
            ambiente(x, y) = 1;
            flores(x, y) = capacidad_flor;
            break;
        end
    end
end

% Generar árboles
for i = 1:num_arboles
    while true
        x_inicio = randi(tamano_grid);
        y_inicio = randi(tamano_grid);
        tamano_arbol = randi([tamano_arbol_min, tamano_arbol_max]); % Tamaño aleatorio
        
        % Condiciones
        if x_inicio + tamano_arbol - 1 <= tamano_grid && ...
           y_inicio + tamano_arbol - 1 <= tamano_grid && ...
           all(all(ambiente(x_inicio:x_inicio+tamano_arbol-1, y_inicio:y_inicio+tamano_arbol-1) == 0)) && ...
           norm([x_inicio - centro_x, y_inicio - centro_y]) > 8 && ...
           any(any(ambiente(max(1, x_inicio-3):min(tamano_grid, x_inicio+3), ...
                            max(1, y_inicio-3):min(tamano_grid, y_inicio+3)) == 1)) % Proximidad a flores
            ambiente(x_inicio:x_inicio+tamano_arbol-1, y_inicio:y_inicio+tamano_arbol-1) = 5;
            break;
        end
    end
end

% Generar abejas
abejas = struct('posicion_x', num2cell(zeros(1, num_abejas)), ...
                'posicion_y', num2cell(zeros(1, num_abejas)), ...
                'estado', num2cell(zeros(1, num_abejas)), ...
                'objetivo_x', num2cell(zeros(1, num_abejas)), ...
                'objetivo_y', num2cell(zeros(1, num_abejas)));

for i = 1:num_abejas
    angulo = 2 * pi * i / num_abejas;
    radio = 5;
    x = centro_x + round(radio * cos(angulo));
    y = centro_y + round(radio * sin(angulo));
    x = max(1, min(tamano_grid, x));
    y = max(1, min(tamano_grid, y));
    if ambiente(x, y) == 0
        abejas(i).posicion_x = x;
        abejas(i).posicion_y = y;
        abejas(i).estado = 0;
        ambiente(x, y) = 3;
    end
end

% Simulación
figure('Position', [100, 100, 1200, 800]);
iteraciones = 0;
while true
    iteraciones = iteraciones + 1;
    flores_restantes = sum(flores(:) > 0);
    
    if flores_restantes == 0 && all([abejas.estado] == 0)
        break;
    end
    hay_abejas_cargadas = any([abejas.estado] == 1);
    
    for i = 1:num_abejas
        x_actual = abejas(i).posicion_x;
        y_actual = abejas(i).posicion_y;
        
        if abejas(i).estado == 0
            % Seleccionar flor aleatoria si no tiene objetivo
            if abejas(i).objetivo_x == 0 || ambiente(abejas(i).objetivo_x, abejas(i).objetivo_y) ~= 1
                [dx, dy] = find(ambiente == 1);
                if ~isempty(dx)
                    idx = randi(length(dx));
                    abejas(i).objetivo_x = dx(idx);
                    abejas(i).objetivo_y = dy(idx);
                end
            end
            
            % Mover hacia la flor
            direccion_x = sign(abejas(i).objetivo_x - x_actual);
            direccion_y = sign(abejas(i).objetivo_y - y_actual);
            nueva_x = x_actual + direccion_x;
            nueva_y = y_actual + direccion_y;
            nueva_x = max(1, min(tamano_grid, nueva_x));
            nueva_y = max(1, min(tamano_grid, nueva_y));
            
            % Evitar colisión con árboles o abejas
            if ambiente(nueva_x, nueva_y) == 0 || ambiente(nueva_x, nueva_y) == 1
                if ambiente(nueva_x, nueva_y) == 1 && flores(nueva_x, nueva_y) > 0
                    abejas(i).estado = 1;
                    flores(nueva_x, nueva_y) = flores(nueva_x, nueva_y) - 1;
                    if flores(nueva_x, nueva_y) == 0
                        ambiente(nueva_x, nueva_y) = 0;
                    end
                    abejas(i).objetivo_x = 0;
                    abejas(i).objetivo_y = 0;
                else
                    ambiente(x_actual, y_actual) = 0;
                    abejas(i).posicion_x = nueva_x;
                    abejas(i).posicion_y = nueva_y;
                    ambiente(nueva_x, nueva_y) = 3;
                end
            end
        elseif abejas(i).estado == 1
            % Mover hacia el panal
            direccion_x = sign(centro_x - x_actual);
            direccion_y = sign(centro_y - y_actual);
            nueva_x = x_actual + direccion_x;
            nueva_y = y_actual + direccion_y;
            
            if ambiente(nueva_x, nueva_y) == 0 || ambiente(nueva_x, nueva_y) == 2
                if ambiente(nueva_x, nueva_y) == 2
                    abejas(i).estado = 0;
                    miel_panal = miel_panal + 1;
                else
                    ambiente(x_actual, y_actual) = 0;
                    abejas(i).posicion_x = nueva_x;
                    abejas(i).posicion_y = nueva_y;
                    ambiente(nueva_x, nueva_y) = 4;
                end
            end
        end
        
        % Dirección alternativa random en caso de estancamiento
        if abejas(i).posicion_x == x_actual && abejas(i).posicion_y == y_actual
            direcciones_posibles = [-1, 0; 1, 0; 0, -1; 0, 1];
            idx = randi(4);
            nueva_x = x_actual + direcciones_posibles(idx, 1);
            nueva_y = y_actual + direcciones_posibles(idx, 2);
            nueva_x = max(1, min(tamano_grid, nueva_x));
            nueva_y = max(1, min(tamano_grid, nueva_y));
            
            if ambiente(nueva_x, nueva_y) == 0 
                ambiente(x_actual, y_actual) = 0;
                abejas(i).posicion_x = nueva_x;
                abejas(i).posicion_y = nueva_y;
                ambiente(nueva_x, nueva_y) = 3;
            end
        end
    end
    
    % Visualización
    if hay_abejas_cargadas
        colormap([1 1 1; % 0: Blanco (vacío)
                  0.5 0 0.5; % 1: Morado (flores)
                  1 1 0; % 2: Amarillo (panal)
                  1 0.647 0; % 3: Naranja (abeja buscando)
                  1 0 0; % 4: Rojo (abeja cargada)
                  0 1 0]); % 5: Verde (árboles)
    else
        colormap([1 1 1; % 0: Blanco (vacío)
                  0.5 0 0.5; % 1: Morado (flores)
                  1 1 0; % 2: Amarillo (panal)
                  1 0.647 0; % 3: Naranja (abeja buscando)
                  0 1 0]); % 4: Verde (árboles)
    end
    imagesc(ambiente);
    title(['Iteración: ', num2str(iteraciones), ' | Miel recolectada: ', num2str(miel_panal)]);
    pause(0.1);
end

toc;