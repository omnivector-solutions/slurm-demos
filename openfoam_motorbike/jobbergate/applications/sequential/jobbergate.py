from jobbergate_cli.subapps.applications.application_base import JobbergateApplicationBase
from jobbergate_cli.subapps.applications.questions import Text

class JobbergateApplication(JobbergateApplicationBase):
    def mainflow(self, *_, **__):
        questions = []

        questions.append(Text(
            "partition",
            message="Choose a partition",
            default="compute"
        ))
        return questions
