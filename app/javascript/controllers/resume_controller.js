import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["projectExperience", "jobDescription", "jobMatch"]

    optimizeProjectExperience() {
        const originalText = this.projectExperienceTarget.value

        fetch('/resumes/work_experiences/optimize', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({ project_experience: originalText })
        })
            .then(response => response.json())
            .then(data => {
                this.projectExperienceTarget.value = data.optimized_text;
            })
            .catch(error => console.error('Error:', error));
    }

    generateJobMatch() {
        const jd = this.jobDescriptionTarget.value
        const resumeId = this.data.get("id");
        console.log(resumeId)
        fetch(`/resumes/${resumeId}/job_match`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({ job_description: jd })
        })
            .then(response => response.json())
            .then(data => {
                this.jobMatchTarget.value = data.job_match;
            })
            .catch(error => console.error('Error:', error));
    }
}