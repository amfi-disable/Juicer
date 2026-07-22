"""Regression tests for the CodeQL SAST GitHub Actions workflow.

This suite guards the change introduced in the PR that bumped the
`actions/setup-node` action used by `.github/workflows/codeql.yml` from
`v4` to `v7`. It verifies the workflow file remains valid YAML, that the
Node.js setup step is pinned to the expected action version, and that no
unrelated steps/pins were accidentally altered by the bump.

Run with (no extra dependencies beyond PyYAML, which is already used by
the project's tooling):

    python3 -m unittest tests/workflows/test_codeql_workflow.py -v
"""

import pathlib
import unittest

import yaml

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
WORKFLOW_PATH = REPO_ROOT / ".github" / "workflows" / "codeql.yml"


def _load_workflow():
    with open(WORKFLOW_PATH, "r", encoding="utf-8") as handle:
        # PyYAML treats the bare `on:` key as the boolean `True` key under
        # the default resolver, so keys must be looked up accordingly.
        return yaml.safe_load(handle)


def _analyze_job_steps():
    workflow = _load_workflow()
    jobs = workflow["jobs"]
    analyze_job = jobs["analyze"]
    return analyze_job["steps"]


def _find_step_by_name(steps, name):
    for step in steps:
        if step.get("name") == name:
            return step
    return None


class TestCodeqlWorkflowFile(unittest.TestCase):
    """Basic sanity checks that the workflow file is present and valid."""

    def test_workflow_file_exists(self):
        self.assertTrue(
            WORKFLOW_PATH.is_file(),
            f"Expected workflow file at {WORKFLOW_PATH}",
        )

    def test_workflow_is_valid_yaml(self):
        workflow = _load_workflow()
        self.assertIsInstance(workflow, dict)
        self.assertIn("jobs", workflow)

    def test_analyze_job_exists(self):
        workflow = _load_workflow()
        self.assertIn("analyze", workflow["jobs"])


class TestSetupNodeStepVersionBump(unittest.TestCase):
    """Verifies the specific change made by this PR: the setup-node bump."""

    def setUp(self):
        self.steps = _analyze_job_steps()
        self.setup_node_step = _find_step_by_name(self.steps, "Setup Node.js 24")

    def test_setup_node_step_present(self):
        self.assertIsNotNone(
            self.setup_node_step,
            "Expected a step named 'Setup Node.js 24' in the analyze job",
        )

    def test_setup_node_action_pinned_to_v7(self):
        self.assertEqual(
            self.setup_node_step["uses"],
            "actions/setup-node@v7",
            "actions/setup-node should be pinned to v7 after the bump",
        )

    def test_setup_node_action_not_reverted_to_v4(self):
        # Explicit regression guard against re-introducing the old,
        # pre-PR pinned version.
        self.assertNotEqual(self.setup_node_step["uses"], "actions/setup-node@v4")

    def test_setup_node_node_version_unchanged(self):
        self.assertEqual(self.setup_node_step["with"]["node-version"], "24")

    def test_only_one_setup_node_step_in_job(self):
        setup_node_steps = [
            step
            for step in self.steps
            if str(step.get("uses", "")).startswith("actions/setup-node@")
        ]
        self.assertEqual(
            len(setup_node_steps),
            1,
            "Expected exactly one actions/setup-node step in the analyze job",
        )


class TestSurroundingWorkflowUnaffected(unittest.TestCase):
    """Ensures the version bump did not touch unrelated steps/pins."""

    def setUp(self):
        self.steps = _analyze_job_steps()

    def test_checkout_step_unchanged(self):
        step = _find_step_by_name(self.steps, "Checkout Code")
        self.assertIsNotNone(step)
        self.assertEqual(step["uses"], "actions/checkout@v4")

    def test_codeql_init_step_unchanged(self):
        step = _find_step_by_name(self.steps, "Initialize CodeQL")
        self.assertIsNotNone(step)
        self.assertEqual(step["uses"], "github/codeql-action/init@v3")
        self.assertEqual(step["with"]["languages"], "swift")

    def test_codeql_analyze_step_unchanged(self):
        step = _find_step_by_name(self.steps, "Perform CodeQL Analysis")
        self.assertIsNotNone(step)
        self.assertEqual(step["uses"], "github/codeql-action/analyze@v3")

    def test_step_order_preserved(self):
        step_names = [step.get("name") for step in self.steps]
        self.assertEqual(
            step_names,
            [
                "Checkout Code",
                "Setup Node.js 24",
                "Select Xcode Version",
                "Install XcodeGen",
                "Initialize CodeQL",
                "Generate Xcode Project",
                "Build Swift Application for CodeQL",
                "Perform CodeQL Analysis",
            ],
        )


if __name__ == "__main__":
    unittest.main()