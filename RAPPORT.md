# Rapport de Développement : FocusFlow

## 1. Présentation du Projet
**FocusFlow** est une application mobile et web de productivité axée sur la méthode Pomodoro. Conçue pour aider les utilisateurs à maintenir leur concentration, elle combine un minuteur de sessions de travail (Focus) et de pauses, tout en y associant un gestionnaire de tâches (To-Do List). 

L'application permet d'améliorer la gestion du temps via un écosystème ludique et structuré comprenant :
- Un minuteur Pomodoro interactif (avec animations circulaires).
- La possibilité d'affecter une tâche spécifique à une session de travail.
- Un système de "Feedback" : à la fin d'une session, l'utilisateur indique s'il a terminé sa tâche, ce qui influence directement ses statistiques.
- Une diffusion de bruits ambiants (pluie, océan, etc.) pour aider à l'immersion.
- Un tableau de bord analytique (Statistiques) permettant de suivre le temps de focus hebdomadaire et le taux de succès (tâches achevées).

## 2. Choix Techniques
Afin de construire une architecture robuste et facilement maintenable, les technologies suivantes ont été sélectionnées :

*   **Frontend : Flutter & Dart**
    *   *Framework UI* multi-plateforme permettant un design fluide, réactif et animé avec une seule base de code.
    *   *State Management* : Le package `provider` a été utilisé (via un `MultiProvider` central) pour séparer la logique métier (`TimerProvider`, `TaskProvider`, `SettingsProvider`, `AuthProvider`) de l'interface utilisateur.
    *   *Composants spécifiques* : `audioplayers` pour la lecture des sons d'ambiance, `fl_chart` pour le tracé de graphiques dynamiques, et `shared_preferences` pour la persistance locale des paramètres (thème, durée du minuteur).
*   **Backend : Node.js & Express**
    *   Serveur RESTful léger traitant les requêtes d'authentification, de gestion des tâches et de sauvegarde des historiques de sessions.
    *   Authentification sécurisée via JSON Web Tokens (JWT).
*   **Base de Données : SQLite & Prisma (ORM)**
    *   Choix de SQLite pour sa simplicité de déploiement en local lors de cette phase de développement.
    *   Prisma agit comme un ORM moderne garantissant le typage fort et facilitant les migrations de schémas (ex: ajout de la colonne `status` pour les sessions Pomodoro).

## 3. Captures d'écran

*(Insérez ici vos captures d'écran de l'application en fonctionnement)*

> [!TIP]
> **Notes de design :** L'interface repose sur le concept du "Dark Mode" profond (`#0F0F1A`) accompagné d'accents vibrants en Violet/Indigo (`#6C63FF`) et Corail/Orange (`#FF6B6B`). Des micro-animations (Pulse du bouton de lecture, Arc de cercle dynamique) renforcent l'expérience "Premium".

## 4. Difficultés rencontrées

Tout au long du développement, plusieurs défis techniques se sont présentés :

1.  **Synchronisation entre le temps réel et l'état global (State Management)** : 
    Faire interagir le minuteur avec la base de données sans provoquer de multiples rechargements d'interface ou geler le compte à rebours. Gérer la "pause" du système pour demander un *feedback* à l'utilisateur à la fin d'une session a nécessité un soin particulier.
2.  **Gestion des Assets et des APIs Web Audio** : 
    Sous Flutter Web (Chrome), la lecture de certains formats audio a retourné des erreurs (ex: `MEDIA_ELEMENT_ERROR: Format error (Code: 4)`).
3.  **Conflits d'UI dans l'arbre des Widgets (Hero Tags)** : 
    Lors du passage vers une navigation par `IndexedStack` (Onglets), une exception `There are multiple heroes that share the same tag within a subtree` bloquait le rendu en raison de l'utilisation redondante du bouton d'action flottant (`FloatingActionButton`) par défaut dans plusieurs écrans simultanés.
4.  **Dépréciation de composants Flutter** : 
    Le framework Flutter évoluant très rapidement, de nombreux avertissements de dépréciation (comme `withOpacity` remplacé par `withValues` ou `activeColor` par `activeTrackColor`) ont pollué l'analyse du code.

## 5. Solutions proposées

Voici comment nous avons répondu à ces problématiques :

1.  **Refactoring du Flux Pomodoro** : 
    Le `TimerProvider` a été restructuré pour capturer l'état `needsFeedback`. À l'instant où un compteur atteint 0, le flux est suspendu pour faire apparaître une boîte de dialogue (UI). Une fois le statut ("completed" ou "failed") récupéré, ce n'est qu'à ce moment-là que l'appel API est déclenché vers Node.js et que la "Pause" démarre.
2.  **Externalisation de l'Audio** : 
    Les URLs des sons ambiants ont été changées pour pointer directement vers des fichiers certifiés et viables via requêtes HTTP directes (ou des bibliothèques externes fiables), contournant les bugs de codec local de Chrome.
3.  **Nettoyage de la structure Scaffold** : 
    Pour résoudre le crash `Hero tag`, le `FloatingActionButton` "fantôme" qui se trouvait dans le conteneur principal (`home_screen.dart`) a été supprimé, laissant le soin aux sous-écrans (comme `tasks_screen.dart`) de gérer leurs propres boutons avec des tags uniques et distincts.
4.  **Mise à jour et Nettoyage du Code** : 
    Les thèmes, constantes de couleurs, et propriétés de Switch/Boutons ont été adaptés à la dernière syntaxe Flutter Material 3 (remplacement des appels `accentColor` et ajustements `CardThemeData`), garantissant 0 erreur de compilation.

## 6. Conclusion
Le projet **FocusFlow** remplit son objectif de proposer un outil ludique, performant et beau visuellement, favorisant la concentration de ses utilisateurs. Les briques logicielles mises en place (Flutter pour un rendu natif fluide et Node.js/Prisma pour un backend souple) permettent d'envisager facilement l'ajout de nouvelles fonctionnalités à l'avenir (ex: Partage de sessions entre amis, synchronisation Cloud multi-appareils, thèmes déblocables).
