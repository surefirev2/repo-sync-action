import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def run_script(script: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(REPO_ROOT / "test" / script)],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
    )


def test_resolve_config_bash_runner():
    proc = run_script("run-resolve-config-tests.sh")
    assert proc.returncode == 0, proc.stdout + proc.stderr
    assert "All resolve-config tests passed." in proc.stdout


def test_build_file_list_bash_runner():
    proc = run_script("run-build-file-list-tests.sh")
    assert proc.returncode == 0, proc.stdout + proc.stderr
    assert "All build-file-list tests passed." in proc.stdout


def test_ga_build_file_list_bash_runner():
    proc = run_script("run-ga-build-file-list-tests.sh")
    assert proc.returncode == 0, proc.stdout + proc.stderr
    assert "All GA build-file-list wrapper tests passed." in proc.stdout


def test_generate_diffs_bash_runner():
    proc = run_script("run-generate-diffs-tests.sh")
    assert proc.returncode == 0, proc.stdout + proc.stderr
    assert "All generate-diffs tests passed." in proc.stdout


def test_write_step_summary_bash_runner():
    proc = run_script("run-write-step-summary-tests.sh")
    assert proc.returncode == 0, proc.stdout + proc.stderr
    assert "All write-step-summary tests passed." in proc.stdout


def test_pr_comment_bash_runner():
    proc = run_script("run-pr-comment-tests.sh")
    assert proc.returncode == 0, proc.stdout + proc.stderr
    assert "All PR comment tests passed." in proc.stdout


def test_push_pr_bash_runner():
    proc = run_script("run-push-pr-tests.sh")
    assert proc.returncode == 0, proc.stdout + proc.stderr
    assert "All push-pr tests passed." in proc.stdout
