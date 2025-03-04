import { Controller } from "@hotwired/stimulus"
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

        this.highlightEachCharacter(element)

        let options = {
            margin:       1,
            filename:     `应聘(XXX)产品经理-(匹配1)-(匹配2)-${this.nameValue}.pdf`,
            image:        { type: 'jpeg', quality: 0.98 },
            html2canvas:  { scale: 2 },
        };

        // Generate and download the PDF
        html2pdf().set(options).from(element).save();
    }

    // 将一整个高亮的 span 切割成每个字符单独高亮
     highlightEachCharacter(container) {
        // 找到所有最外层的含有特定样式的 span 元素
        const outerSpans = container.querySelectorAll('span[style*="background-color: yellow;"]');

        outerSpans.forEach(outerSpan => {
            // 获取 span 的文本内容
            const text = outerSpan.innerText;
            let highlightedText = '';

            // 遍历文本内容的每个字符，将其包装在单独的 span 中，并应用高亮样式
            Array.from(text).forEach(char => {
                highlightedText += `<span style="background-color: yellow;">${char}</span>`;
            });

            // 创建一个临时容器 div
            const tempDiv = document.createElement('div');
            // 将生成的字符串设置为这个临时 div 的内容
            tempDiv.innerHTML = highlightedText;

            // 使用文档片段来移除最外层的 span 并添加处理过的字符
            const docFrag = document.createDocumentFragment();
            while (tempDiv.firstChild) {
                docFrag.appendChild(tempDiv.firstChild);
            }

            // 将新内容插入到原来 span 的父元素中，并移除原来的 span
            outerSpan.parentNode.replaceChild(docFrag, outerSpan);
        });
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