import {Controller} from "@hotwired/stimulus"
// import html2pdf from "html2pdf";
import Quill from "quill";

export default class extends Controller {
    static targets = ["projectExperience", "jobDescription", "jobMatch", "jobMatchPreview", "pdfSource", "highlight", "switchButton", "optimizeButton", "jobMatchButton"]

    static values = {
        name: String,
        experienceType: String
    }

    connect() {
        if (this.hasHighlightTarget) {
            this.updateSwitchState();
        }

        if (document.querySelector('#job-match-editor')) {
            this.initializeQuill();
        }
    }

    initializeQuill() {
        this.editor = new Quill('#job-match-editor', {
            theme: 'snow',
            modules: {
                toolbar: [
                    ['bold'],
                    // [{ 'list': 'bullet' }], // TODO: implement this
                    [{ 'background': ['white', 'yellow'] }], // background color
                ]
            }
        });

        // 监听编辑器内容的变化
        this.editor.on('text-change', () => {
            this.jobMatchTarget.value = this.editor.root.innerHTML;
            this.updateJobMatchPreview();
        });
    }

    optimizeProjectExperience() {
        const originalText = this.projectExperienceTarget.value
        const experienceType = this.experienceTypeValue;
        const button = this.optimizeButtonTarget;

        // Disable the button and add animation
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);

        fetch('/resumes/work_experiences/optimize', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({
                project_experience: originalText,
                experience_type: experienceType
            })
        })
            .then(response => response.json())
            .then(data => {
                this.projectExperienceTarget.value = data.optimized_text;
                // Restore the button's state after successful operation
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            })
            .catch(error => {
                console.error('Error:', error);
                // Also restore the button's state in case of error
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            });
    }

    generateJobMatch() {
        const jd = this.jobDescriptionTarget.value
        const button = this.jobMatchButtonTarget;
        if (!jd) {
            alert("请输入职位 JD 内容")
            return
        }
        button.classList.add('cursor-not-allowed', 'animate-bounce');
        button.setAttribute('disabled', true);

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
                this.editor.setText(data.job_match);
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            })
            .catch(error => {
                console.error('Error:', error)
                button.classList.remove('cursor-not-allowed', 'animate-bounce');
                button.removeAttribute('disabled');
            });
    }

    downloadPDF() {
        this.updateJobMatchPreview(); // up to date job match preview
        let element = this.pdfSourceTarget; // Adjust if necessary to match your HTML structure
        console.log(element)

        let tempDiv = document.createElement('div');
        tempDiv.innerHTML = `
  <div class="mt-2" id="job-match-preview" data-resume-target="jobMatchPreview" element-id="41">
    <p>• 有产品设计经验和优秀的自驱力：通过自学Axure在5天内完成大学生租房产品设计方案，包含房源信息、用户系统、租房经验等9个页面的设计。</p>
    <p>• 有需求分析和用户调研经验：通过用户反馈和业务数据的分析，提升产品运营效率，<span style="background-color: yellow;">为</span><span style="background-color: yellow;">研</span><span style="background-color: yellow;">发</span><span style="background-color: yellow;">团</span><span style="background-color: yellow;">队</span><span style="background-color: yellow;">提</span><span style="background-color: yellow;">供</span><span style="background-color: yellow;">1</span><span style="background-color: yellow;">7</span><span style="background-color: yellow;">项</span><span style="background-color: yellow;">优</span><span style="background-color: yellow;">化</span><span style="background-color: yellow;">建</span><span style="background-color: yellow;">议</span><span style="background-color: yellow;">。</span></div></p>
    <p>• 有一定的数据分析能力：通过参与AI内容编辑工作，贡献于模型准确率提升至77%。</p>
  </div>`;
        let options = {
            margin:       1,
            filename:     `应聘(XXX)产品经理-(匹配1)-(匹配2)-${this.nameValue}.pdf`,
            image:        { type: 'jpeg', quality: 0.98 },
            html2canvas:  { scale: 2 },
        };

        // Generate and download the PDF
        html2pdf().set(options).from(tempDiv).save();
    }

    updateJobMatchPreview() {
        const htmlContent = this.jobMatchTarget.value;

        // 创建一个临时的 div 元素
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = htmlContent;

        // 为所有的 <ol> 元素添加 Tailwind CSS 类
        const unorderedLists = tempDiv.querySelectorAll('ul');
        unorderedLists.forEach(ul => {
            ul.classList.add('list-disc', 'list-inside');
        });

        // 将处理后的 HTML 设置回预览区
        this.jobMatchPreviewTarget.innerHTML = tempDiv.innerHTML;
    }

    toggleHighlightSwitch() {
        // Toggle the checkbox value
        this.highlightTarget.checked = !this.highlightTarget.checked;
        this.updateSwitchState();
    }

    updateSwitchState() {
        const isChecked = this.highlightTarget.checked;
        const switchButton = this.switchButtonTarget;
        const switchIndicator = switchButton.querySelector("span");

        if (isChecked) {
            switchButton.classList.replace("bg-gray-200", "bg-indigo-600");
            switchIndicator.classList.replace("translate-x-0", "translate-x-5");
            switchButton.setAttribute("aria-checked", "true");
        } else {
            switchButton.classList.replace("bg-indigo-600", "bg-gray-200");
            switchIndicator.classList.replace("translate-x-5", "translate-x-0");
            switchButton.setAttribute("aria-checked", "false");
        }
    }
}