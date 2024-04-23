import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["companyDescription", "jobDescription", "interviewQuestions", "analysisButton", "selfIntroductionButton", "potentialInterviewQuestionsButton", "selfIntroductionResponse", "potentialInterviewQuestionsResponse", "interviewQuestionsAnalysisResponse", "resumeFile"]

    analyzeInterviewQuestions() {
        const companyDescription = this.companyDescriptionTarget.value
        const jobDescription = this.jobDescriptionTarget.value
        const interviewQuestions = this.interviewQuestionsTarget.value
        if (!interviewQuestions) {
            alert("请填写面试问题");
            return;
        }
        const button = this.analysisButtonTarget

        const resumeId = this.data.get("id");

        // Disable the button and add animation
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);

        fetch(`/resumes/${resumeId}/analyze_interview_questions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({
                company_description: companyDescription,
                job_description: jobDescription,
                interview_questions: interviewQuestions
            })
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
        const resumeFile = this.resumeFileTarget.files[0];  // Get the file from the file input
        if (!resumeId && !resumeFile) {
            alert("请上传你的 PDF 简历")
            return
        };  // Exit if no file is selected

        const companyDescription = this.companyDescriptionTarget.value
        const jobDescription = this.jobDescriptionTarget.value
        const button = this.selfIntroductionButtonTarget


        const formData = new FormData();
        formData.append('company_description', companyDescription);
        formData.append('job_description', jobDescription);
        if (resumeFile) {
            formData.append('resume_file', resumeFile);
        }
        if (resumeId) {
            formData.append('resume_id', resumeId);
        }

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

    potentialInterviewQuestions() {
        const companyDescription = this.companyDescriptionTarget.value
        const jobDescription = this.jobDescriptionTarget.value
        const interviewQuestions = this.interviewQuestionsTarget.value
        const button = this.potentialInterviewQuestionsButtonTarget

        const resumeId = this.data.get("id");

        // Disable the button and add animation
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);

        fetch(`/resumes/${resumeId}/potential_interview_questions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({
                company_description: companyDescription,
                job_description: jobDescription,
            })
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
}