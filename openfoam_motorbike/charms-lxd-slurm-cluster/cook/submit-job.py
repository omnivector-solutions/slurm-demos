import sys

import httpx

username = sys.argv[1]
token = sys.argv[2]
slurmrestd_endpoint = sys.argv[3]

job_script = httpx.get(
    "https://raw.githubusercontent.com/omnivector-solutions/slurm-demos/main/openfoam_motorbike/charms-lxd-slurm-cluster/run-motorbike-parallel.sh"
).text

slurmrestd_response = httpx.post(
    slurmrestd_endpoint,
    headers={
        "X-SLURM-USER-NAME": username,
        "X-SLURM-USER-TOKEN": token,
        "Content-Type": "application/json",
    },
    json={
        "script": job_script,
        "job": {
            "get_user_environment": "1",
            "partition": "osd-slurmd",
            "tasks": 6,
            "name": "motorbike-par",
            "standard_output": "/nfs/R-%x.%j.out",
            "standard_error": "/nfs/R-%x.%j.err",
            "current_working_directory": "/nfs",
            "time_limit": 1800,
        }
    }
)
print("Slurmrestd response code: {}".format(slurmrestd_response.status_code))
print("Slurmrestd response text: {}".format(slurmrestd_response.text))