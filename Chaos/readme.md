Startup pyenv

```bash
python3.7 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

Deploy simple site in nginx

Run an experiment to terminate an instance

```bash
chaos run terminate_instance/experiment.json
```
