# Activity Recognition App 🚶‍♂️📱

Aplicativo construído para avaliação na disciplina **Aplicações de Aprendizado de Máquina em Sistemas Embarcados** no Mestrado Profissional em Engenharia de Produção e Sistemas Computacionais (MESC) - UFF - Rio das Ostras.

O projeto contém o notebook utilizado para o treinamento do modelo de reconhecimento de atividades humanas e o projeto final desenvolvido para dispositivos móveis. O objetivo principal é aplicar técnicas de aprendizado de máquina para classificar atividades com base em dados de sensores.

---
## Dataset 📊

O modelo foi treinado utilizando o **WISDM (Wireless Sensor Data Mining) Lab: Dataset**. Este conjunto de dados é amplamente utilizado para pesquisa em reconhecimento de atividades e contém dados de acelerômetros de smartphones.

**Referência do Dataset:**
* Jennifer R. Kwapisz, Gary M. Weiss and Samuel A. Moore (2010). Activity Recognition using Cell Phone Accelerometers, Proceedings of the Fourth International Workshop on Knowledge Discovery from Sensor Data (at KDD-10), Washington DC.

---
## Metodologia e Ferramentas 🛠️

O processo de desenvolvimento envolveu as seguintes etapas e ferramentas:

* **Pré-processamento dos dados**: Utilização das bibliotecas **Pandas** e **Numpy** para limpeza, transformação e preparação dos dados do acelerômetro.
* **Treinamento do Modelo**: Implementação e treinamento de um modelo de aprendizado de máquina com **TensorFlow**.
* **Conversão e Otimização**: O modelo treinado foi convertido para o formato **TensorFlow Lite** (`.tflite`), otimizado para inferência em dispositivos móveis com recursos limitados.
* **Desenvolvimento Mobile**: Integração do modelo `.tflite` em um aplicativo móvel para reconhecimento de atividades em tempo real.

---
## Referência Principal 📜

A metodologia de conversão do modelo TensorFlow para TensorFlow Lite e sua implantação em smartphones, bem como a comparação de desempenho, foi inspirada e guiada pela seguinte dissertação/trabalho final:

* Mitra Rashidi. *Application of TensorFlow lite on embedded devices: A hands-on practice of TensorFlow model conversion to TensorFlow Lite model and its deployment on Smartphone to compare model’s performance.* Computer Engineering BA (C), Final Project. Sundsvall 2022-06-23.

---

Este projeto demonstra uma aplicação prática de aprendizado de máquina em sistemas embarcados, desde a coleta e processamento de dados até a implementação de um modelo eficiente em um dispositivo móvel.
