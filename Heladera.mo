model Heladera
// Proyecto Integrador - Modelos y Simulaciones 2026

  // --- PARÁMETROS DEL SISTEMA ---
  parameter Real C_termica = 15000 "Capacidad térmica del sistema [J/K]";
  parameter Real R_paredes = 0.2   "Resistencia térmica de paredes [K/W]";
  parameter Real Potencia_refrigeracion = 1200 "Capacidad de enfriamiento [W]";
  parameter Real COP = 2.5         "Coeficiente de eficiencia";
  parameter Real T_set_max = 6     "Temp para arrancar compresor [C]";
  parameter Real T_set_min = 2     "Temp para detener compresor [C]";
  parameter Real Tasa_Calor_Puerta = 150 "Potencia inyectada con puerta abierta [W]";
  parameter Real Duracion_Evento = 30    "Duración de cada 'pulso' de apertura [s]";

  // --- PARÁMETRO DE POLÍTICA (cambiar para el experimento) ---
  parameter Real Tiempo_Apertura_Base = 5 "Segundos promedio de apertura [s]";
  // Política A (base): 15 s → Política B (mejora): 5 s

  // --- VARIABLES CON INCERTIDUMBRE ---
  Real T_ext              "1. Temp exterior [C] — incertidumbre climática";
  Real Evento_Apertura    "2. Señal de apertura de puerta [0 o 1] — llegada de clientes";
  Real Tiempo_Apertura_Real "3. Tiempo real de apertura por persona [s] — comportamiento humano";

  // --- VARIABLES DE ESTADO ---
  Real T_int(start = 4)           "4. Temperatura interior [C]";
  Real Q_paredes                  "5. Calor ingresando por paredes [W]";
  Real Q_puerta                   "6. Calor inyectado por apertura [W]";
  Real Potencia_electrica         "7. Potencia consumida por compresor [W]";
  Real Energia_consumida(start=0) "8. Energía eléctrica acumulada [J]";
  Real Factor_Apertura            "9. Fracción del tiempo que la puerta está abierta [-]";
  Boolean estado_compresor(start = false) "10. Estado del compresor";

algorithm
  // Histéresis del compresor — correcta en bloque algorithm
  when T_int > T_set_max then
    estado_compresor := true;
  elsewhen T_int < T_set_min then
    estado_compresor := false;
  end when;

equation
  // --- INCERTIDUMBRE 1: Temperatura exterior (ciclo diurno) ---
  T_ext = 22 + 8 * sin(2 * Modelica.Constants.pi * time / 86400)
             + 2 * sin(2 * Modelica.Constants.pi * time / 3600);

  // --- INCERTIDUMBRE 2: Evento de apertura (pseudo-aleatorio) ---
  Evento_Apertura = if (sin(2 * Modelica.Constants.pi * time / 1800)
                      + sin(2 * Modelica.Constants.pi * time / 1100)) > 1.8
                    then 1.0 else 0.0;

  // --- INCERTIDUMBRE 3: Tiempo real de apertura (variación humana) ---
  Tiempo_Apertura_Real = max(1.0, Tiempo_Apertura_Base
                          + 4 * sin(2 * Modelica.Constants.pi * time / 500));

  // Factor de apertura: fracción del tiempo en que la puerta está abierta
  // (Tiempo_Apertura_Real segundos cada Duracion_Evento segundos de ciclo)
  Factor_Apertura = Evento_Apertura * min(1.0, Tiempo_Apertura_Real / Duracion_Evento);

  // --- TÉRMICA ---
  Q_paredes = (T_ext - T_int) / R_paredes;

  // Q_puerta en Watts: potencia × fracción del tiempo abierta
  Q_puerta = Factor_Apertura * Tasa_Calor_Puerta;

  Potencia_electrica = if estado_compresor then (Potencia_refrigeracion / COP) else 0;

  // --- ECUACIONES DIFERENCIALES ---
  der(T_int) = (Q_paredes + Q_puerta
               - (if estado_compresor then Potencia_refrigeracion else 0)) / C_termica;

  der(Energia_consumida) = Potencia_electrica;


annotation(
    experiment(StartTime = 0, StopTime = 604800, Tolerance = 1e-06, Interval = 1209.6));
end Heladera;
