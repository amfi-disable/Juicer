# ui improvement checklist

This is the product-wide UI checklist for Juicer. Shared improvements are implemented in reusable components where possible.

## navigation and shell

1. Add a real floating background to BetterCmdTab.
2. Keep BetterCmdTab above other apps and across Spaces.
3. Allow Escape to dismiss every overlay.
4. Add a searchable tool sidebar.
5. Keep the hub usable in short windows.
6. Add a comfortable default window size.
7. Preserve workspace selection when returning from a tool.
8. Add a visible back-to-hub affordance.
9. Add selected-state contrast in every sidebar row.
10. Add tooltips to icon-only controls.
11. Add keyboard focus rings.
12. Add full keyboard navigation for sidebar tools.
13. Add recent-tools navigation.
14. Add favorites to the sidebar.
15. Add a sidebar compact mode.
16. Add a sidebar width preference.
17. Add breadcrumbs to deep tools.
18. Add a global command palette.
19. Add a quick switcher for workspaces.
20. Preserve the last selected tool on relaunch.

## headers and cards

21. Give every feature header a consistent icon badge.
22. Make header subtitles wrap instead of truncate.
23. Add a consistent refresh button style.
24. Add refresh tooltips.
25. Show refresh progress visibly.
26. Disable destructive actions while work runs.
27. Standardize card corner radii.
28. Standardize card borders.
29. Use material backgrounds for translucent surfaces.
30. Improve metric tile vertical rhythm.
31. Support long metric values without clipping.
32. Add status colors with semantic meaning.
33. Increase minimum card hit targets.
34. Add hover feedback to interactive cards.
35. Add pressed feedback to buttons.
36. Use consistent section spacing.
37. Align action buttons to a common baseline.
38. Make empty cards use native unavailable states.
39. Add copy affordances for technical values.
40. Add selection affordances to list rows.

## feedback and state

41. Replace silent failures with inline error banners.
42. Add success confirmation styling.
43. Add warning styling for privileged operations.
44. Keep errors selectable for bug reports.
45. Show last updated timestamps.
46. Show determinate progress when possible.
47. Show indeterminate progress when duration is unknown.
48. Add cancellation actions to long operations.
49. Preserve output while refreshing.
50. Add retry buttons to recoverable failures.
51. Add loading placeholders to slow views.
52. Add empty-state explanations and next actions.
53. Add offline states to network tools.
54. Add permission-state explanations.
55. Add accessibility-state explanations.
56. Avoid layout jumps when messages appear.
57. Announce operation results to VoiceOver.
58. Add confirmation for destructive actions.
59. Show affected item counts before deletion.
60. Add undo where the operation supports it.

## forms and controls

61. Validate paths before enabling actions.
62. Validate ports as the user types.
63. Add inline validation messages.
64. Select all text on first focus for short fields.
65. Add clear buttons to searchable fields.
66. Add reveal-in-finder buttons for paths.
67. Add file and folder pickers beside path fields.
68. Use appropriate keyboard types for numeric fields.
69. Add submit shortcuts to forms.
70. Add cancel shortcuts to sheets.
71. Keep primary actions visually dominant.
72. Group related controls into labeled sections.
73. Explain risky settings beside the control.
74. Add reset controls next to customizable settings.
75. Persist form drafts during modal editing.
76. Restore focus after modal dismissal.
77. Use menus for long enumerations.
78. Use segmented controls for short mutually exclusive choices.
79. Add disabled-state explanations.
80. Make toggles describe their enabled behavior.

## utilities and overlays

81. Show BetterCmdTab application icons at a predictable size.
82. Show BetterCmdTab app names without truncating too aggressively.
83. Highlight the keyboard dismissal action.
84. Center overlays on the active display.
85. Avoid attaching global utilities to the main window.
86. Add a clear enabled/disabled state to every utility.
87. Explain required macOS permissions before activation.
88. Add hotkey conflict detection.
89. Add hotkey recording controls.
90. Add a test button for each global utility.
91. Keep utility panels above full-screen spaces where supported.
92. Restore utility panel positions.
93. Add a compact utility panel mode.
94. Add utility status indicators to the menu bar.
95. Add clipboard item copy feedback.
96. Add clipboard history clearing confirmation.
97. Add scratchpad character count.
98. Add loupe color format choices.
99. Add tiler display selection.
100. Add a utilities troubleshooting link.
