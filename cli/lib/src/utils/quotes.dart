import 'dart:math';

/// A famous quote from the Somnio team.
class SomnioQuote {
  const SomnioQuote(this.text, this.author);

  final String text;
  final String author;
}

/// Returns a random quote from the Somnio team.
SomnioQuote getRandomQuote() {
  final random = Random();
  return _quotes[random.nextInt(_quotes.length)];
}

const _quotes = <SomnioQuote>[
  SomnioQuote(
    'Una vez pensé que estaba quedando sorda, pero en realidad es que solo soy distraída',
    'Emilia Astray',
  ),
  SomnioQuote(
    'Es difícil ser el Reja',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'Desubicado como chorizo en ensalada de fruta',
    'Marcos Tort',
  ),
  SomnioQuote(
    '¿Pediste gracias por la comida?',
    'Marcos Tort',
  ),
  SomnioQuote(
    'Por qué ganó Francia el mundial pasado y no un Europeo?',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'Copié y pegué y funcionó',
    'Carol Glass',
  ),
  SomnioQuote(
    'What a table',
    'Carol Glass',
  ),
  SomnioQuote(
    'Vieron que sobran 2 horas de commitment semanal. En esas 2 horas me mamo',
    'Gonzalo Sosa',
  ),
  SomnioQuote(
    'Nunca mezclen fernet con whisky',
    'Paul Pérez',
  ),
  SomnioQuote(
    'El arroz no era pollo',
    'Marcos Tort',
  ),
  SomnioQuote(
    'Ante la duda, siempre Romi',
    'Romina Medeiros',
  ),
  SomnioQuote(
    'Si cerras los ojos no se ve nada',
    'Belen Struyas',
  ),
  SomnioQuote(
    'No estaba agarrada del cosito, estaba agarrada de mi coso',
    'Mariana Mendez',
  ),
  SomnioQuote(
    'Es una plancha ese Varela, el del otro cuadro',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'De tantas bolucompras, te vas a volver una bolu Flor',
    'Mauricio Pastorini',
  ),
  SomnioQuote(
    'Nada mas lindo que ver a un colorado contento',
    'Marcos Tort',
  ),
  SomnioQuote(
    'No está mal estar loco, te divertis más',
    'Romina Medeiros',
  ),
  SomnioQuote(
    'Somos efímeros, hay que vivir el hoy como si fuera el ultimo día',
    'Adrián Claverí',
  ),
  SomnioQuote(
    'Cómo reconoces a un Zombie de Uruguay? Toma mate dulce?',
    'Marcos Tort',
  ),
  SomnioQuote(
    'El que labura pierde',
    'Federico Lopez',
  ),
  SomnioQuote(
    'Todos los caminos llevan a Jackson',
    'Micaela Susviela',
  ),
  SomnioQuote(
    '¿Me voy en auto o me voy manejando?',
    'Joaquina Peterson',
  ),
  SomnioQuote(
    'Me encanta charlar',
    'Carol Glass',
  ),
  SomnioQuote(
    'Ay equipo, felices reyes!! Hoy es 6 de enero',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'Chivito extiende de sanguche',
    'Ignacio Lauret',
  ),
  SomnioQuote(
    'Con el relleno de las empanadas de Madre Mía me hago un guiso',
    'Marcos Tort',
  ),
  SomnioQuote(
    'El funcionamiento esta funcionando?',
    'Carol Glass',
  ),
  SomnioQuote(
    'Yo hice el GPT',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'Yo genero lazos afectivos con mis cosas materiales',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'No hay que saber todo, hay que saber buscar en Google',
    'Adrián Claverí',
  ),
  SomnioQuote(
    'Ningún plan sobrevive al contacto con el futuro',
    'Marcos Tort',
  ),
  SomnioQuote(
    'Soy una teclada del obrero',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'En mi cumpleaños ni voy a tomar alcohol, voy a ser abigeato',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'Qué haces almorzando comiendo?',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'Que vara que está la baja',
    'Florencia Lopez',
  ),
  SomnioQuote(
    'Javascript es como el amor, un lenguaje universal',
    'Adrián Claverí',
  ),
  SomnioQuote(
    '¿Por qué se habrá mudado tanta gente este mes? Será por la luna...',
    'Belen Struyas',
  ),
  SomnioQuote(
    'En México vi militares que iban con animal print',
    'Daniella Carpentieri',
  ),
  SomnioQuote(
    'Belu no es mala, pero yo si lo soy',
    'Antonia Mescia',
  ),
  SomnioQuote(
    'No tengan miedo a fallar',
    'Marcos Tort',
  ),
  SomnioQuote(
    'Caigan con la remera de Peñarol y los bombos',
    'Amanda Suárez',
  ),
  SomnioQuote(
    'La vida es dura y se trata de eso',
    'Agustina Marrero',
  ),
  SomnioQuote(
    'De ahora en mas, las decisiones en Somnio se toman en 10 segundos',
    'Elian Ortega',
  ),
  SomnioQuote(
    'Prefiero eso que pensar',
    'Adrián Claverí',
  ),
  SomnioQuote(
    'Soy enemigo de la pala',
    'Adrián Claverí',
  ),
  SomnioQuote(
    'Me van a poner a pintar la somnio house',
    'Antonio Giler',
  ),
  SomnioQuote(
    'Siempre arriba nosotros, siempre terraza',
    'Belén Silvotti',
  ),
  SomnioQuote(
    'El internet fue hecho para ser navegable, no seguro',
    'Marcos Tort',
  ),
];
