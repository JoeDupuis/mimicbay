module ApplicationHelper
  def form_errors(instance, **locals)
    locals[:instance] = instance
    render partial: "application/form_errors", locals: locals
  end

  def flash_message(message, type: "secondary")
    return nil if message.blank?

    tag.div(
      class: [ "flash-alert", "-#{type}" ].join(" "),
      'data-controller': "alert",
      'data-target': "alert",
      'data-alert-close-btn-class': "close",
      role: "alert"
    ) do
      message
    end
  end
end
