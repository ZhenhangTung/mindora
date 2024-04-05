module ResumesHelper
  def step_indicator_class(step, current_step)
    base_class = 'absolute left-0 top-0 h-full w-1 lg:bottom-0 lg:top-auto lg:h-1 lg:w-full'
    # Determine the color class based on the current step
    color_class = if step == current_step
                    'bg-indigo-600' # Current step
                  else
                    current_step_before(step, current_step) ? 'bg-indigo-600' : 'bg-transparent group-hover:bg-gray-200'
                  end
    "#{base_class} #{color_class}"
  end

  def step_indicator_border_class(step, current_step)
    base_class = 'flex h-10 w-10 items-center justify-center rounded-full border-2'
    # Determine the color class based on the current step

    color_class = if step == current_step
                    'border-indigo-600' # Current step
                  else
                    current_step_before(step, current_step) ? 'border-indigo-600' : 'border-gray-300'
                  end
    "#{base_class} #{color_class}"
  end

  def step_indicator_text_class(step, current_step)
    if step == current_step
      'text-indigo-600' # Current step
    else
      current_step_before(step, current_step) ? 'text-indigo-600' : 'text-gray-500'
    end
  end

  def step_completed?(step, current_step)
    current_step_before(step, current_step)
  end

  def current_step_before(step, current_step)
    steps_order = ['new_resume', 'show_resume', 'customize_resume', 'prepare_interviews']
    steps_order.index(step) < steps_order.index(current_step)
  end
end
