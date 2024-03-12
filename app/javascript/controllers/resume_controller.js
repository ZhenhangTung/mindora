import {Controller} from "@hotwired/stimulus"
// import html2pdf from "html2pdf";

export default class extends Controller {
    static targets = ["projectExperience", "jobDescription", "jobMatch", "jobMatchPreview", "pdfSource"]

    static values = {
        name: String
    }
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
        if (!jd) {
            alert("请输入职位 JD 内容")
            return
        }
        const resumeId = this.data.get("id");
        let jobMatch = ''
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
                jobMatch = data.job_match;
                this.jobMatchTarget.value = jobMatch;
            }).then(() => {
                // Assuming 'response' contains your text from the server
                document.getElementById("job-match-preview").innerHTML = jobMatch.replace(/\r?\n/g, '<br>');
            })
            .catch(error => console.error('Error:', error));
    }

    downloadPDF() {
        let element = this.pdfSourceTarget // Adjust if necessary to match your HTML structure
        let options = {
            margin:       1,
            filename:     `应聘(XXX)产品经理-(匹配1)-(匹配2)-${this.nameValue}.pdf`,
            image:        { type: 'jpeg', quality: 0.98 },
            html2canvas:  { scale: 2 },
        };

        // Generate and download the PDF
        html2pdf().set(options).from(element).save();
    }

    updateJobMatchPreview() {
        const text = this.jobMatchTarget.value;
        this.jobMatchPreviewTarget.innerHTML = text.replace(/\n/g, '<br>');
    }
}