class LevelCatalog {
  static const int maxLevel = 3;

  static const Map<int, List<GameMeta>> levelGames = {
    1: [
      GameMeta(
        gameKey: 'shape_match',
        gameTitle: 'Shape Match Game',
        routeKey: 'l1_shape',
      ),
      GameMeta(
        gameKey: 'animal_guess',
        gameTitle: 'Animal Guess Game',
        routeKey: 'l1_animal',
      ),
      GameMeta(
        gameKey: 'pattern_recognition',
        gameTitle: 'Pattern Recognition Game',
        routeKey: 'l1_pattern',
      ),
    ],
    2: [
      GameMeta(
        gameKey: 'memory_sequence',
        gameTitle: 'Memory Sequence Game',
        routeKey: 'l2_memory',
      ),
      GameMeta(
        gameKey: 'category_sorting',
        gameTitle: 'Category Sorting Game',
        routeKey: 'l2_sorting',
      ),
      GameMeta(
        gameKey: 'picture_logic',
        gameTitle: 'Picture Logic Game',
        routeKey: 'l2_picture_logic',
      ),
    ],
    3: [
      GameMeta(
        gameKey: 'logic_grid_match',
        gameTitle: 'Logic Grid Match Game',
        routeKey: 'l3_logic_grid',
      ),
      GameMeta(
        gameKey: 'sequence_builder',
        gameTitle: 'Sequence Builder Game',
        routeKey: 'l3_sequence_builder',
      ),
      GameMeta(
        gameKey: 'smart_analogy',
        gameTitle: 'Smart Analogy Challenge',
        routeKey: 'l3_smart_analogy',
      ),
    ],
  };

  static int totalGames(int levelNumber) => levelGames[levelNumber]?.length ?? 0;

  static String levelId(int levelNumber) => 'level_$levelNumber';
}

class GameMeta {
  final String gameKey;
  final String gameTitle;
  final String routeKey;

  const GameMeta({
    required this.gameKey,
    required this.gameTitle,
    required this.routeKey,
  });
}