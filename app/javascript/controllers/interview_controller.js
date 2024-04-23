import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["companyDescription", "jobDescription", "interviewQuestions", "analysisButton", "selfIntroductionButton", "potentialInterviewQuestionsButton", "selfIntroductionResponse", "potentialInterviewQuestionsResponse", "interviewQuestionsAnalysisResponse", "resumeFile"]

    analyzeInterviewQuestions(event) {
        event.preventDefault()
        const resumeId = this.data.get("id");
        let resumeFile = null
        if (this.hasResumeFileTarget) {
            resumeFile = this.resumeFileTarget.files[0];  // Get the file from the file input
        }
        if (!resumeId && !resumeFile) {
            alert("请上传你的 PDF 简历")
            return
        };

        const formData = this.buildBasicForm(resumeId, resumeFile)

        const interviewQuestions = this.interviewQuestionsTarget.value
        if (!interviewQuestions) {
            alert("请填写面试问题");
            return;
        }
        formData.append('interview_questions', interviewQuestions);

        const button = this.analysisButtonTarget

        // Disable the button and add animation
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);

        fetch(`/interviews/analyze_interview_questions`, {
            method: 'POST',
            headers: {
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: formData
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(data => {
                this.interviewQuestionsAnalysisResponseTarget.innerText = data.analysis;
            })
            .catch(error => {
                // Handle the error
                console.error('There has been a problem with your fetch operation:', error);
                this.interviewQuestionsAnalysisResponseTarget.innerText = "抱歉，发生了请求错误";
            })
            .finally(() => {
                // This block will run regardless of the fetch outcome.
                // Re-enable the button and stop animation here
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            });
    }

    selfIntroduction(event) {
        event.preventDefault()
        const resumeId = this.data.get("id");
        let resumeFile = null
        if (this.hasResumeFileTarget) {
            resumeFile = this.resumeFileTarget.files[0];  // Get the file from the file input
        }
        if (!resumeId && !resumeFile) {
            alert("请上传你的 PDF 简历")
            return
        };  // Exit if no file is selected
        const button = this.selfIntroductionButtonTarget

        const formData = this.buildBasicForm(resumeId, resumeFile)

        // Disable the button and add animation
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);


        fetch(`/interviews/self_introduction`, {
            method: 'POST',
            headers: {
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: formData
        }).then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
            .then(data => {
                this.selfIntroductionResponseTarget.innerText = data.self_introduction;
            })
            .catch(error => {
                // Handle the error
                console.error('There has been a problem with your fetch operation:', error);
                this.selfIntroductionResponseTarget.innerText = "抱歉，发生了请求错误";
            })
            .finally(() => {
                // This block will run regardless of the fetch outcome.
                // Re-enable the button and stop animation here
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            });
    }

    potentialInterviewQuestions(event) {
        event.preventDefault()
        const resumeId = this.data.get("id");
        let resumeFile = null
        if (this.hasResumeFileTarget) {
            resumeFile = this.resumeFileTarget.files[0];  // Get the file from the file input
        }
        if (!resumeId && !resumeFile) {
            alert("请上传你的 PDF 简历")
            return
        };

        const formData = this.buildBasicForm(resumeId, resumeFile)

        const button = this.potentialInterviewQuestionsButtonTarget


        // Disable the button and add animation
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);

        fetch(`/interviews/potential_interview_questions`, {
            method: 'POST',
            headers: {
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: formData
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(data => {
                this.potentialInterviewQuestionsResponseTarget.innerText = data.interview_questions;
            })
            .catch(error => {
                // Handle the error
                console.error('There has been a problem with your fetch operation:', error);
                this.potentialInterviewQuestionsResponseTarget.innerText = "抱歉，发生了请求错误";
            })
            .finally(() => {
                // This block will run regardless of the fetch outcome.
                // Re-enable the button and stop animation here
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            });
    }

    buildBasicForm(resumeId, resumeFile) {
        const companyDescription = this.companyDescriptionTarget.value
        const jobDescription = this.jobDescriptionTarget.value

        const formData = new FormData();
        formData.append('company_description', companyDescription);
        formData.append('job_description', jobDescription);
        if (resumeFile) {
            formData.append('resume_file', resumeFile);
        }
        if (resumeId) {
            formData.append('resume_id', resumeId);
        }
        return formData
    }
}