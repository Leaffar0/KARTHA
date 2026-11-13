texto = "QUEIMADO";
cor_texto = c_red;
vida_texto = 0;
vida_texto_max = 50; // quantos frames o efeito dura no total
velocidade_subida = 0.8;
oscilacao_intensidade = 3;
visible = true;
// Fora de -16000..16000 o GameMaker não desenha a instância, nem na GUI.
// GUI End garante a sobreposição; a profundidade deve continuar válida.
depth = -15000;
