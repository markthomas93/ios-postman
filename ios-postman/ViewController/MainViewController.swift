import UIKit
import SnapKit
import RxSwift

class MainViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let request: Request
    
    private lazy var urlActionMenuButton: UIButton = {
        let button = UIButton()
        
        button.contentEdgeInsets = .init(top: 5, left: 10, bottom: 5, right: 10)
        button.setTitle(HTTPMethods.get.rawValue, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .appButtonColor
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        
        return button
    }()
    
    private lazy var baseURLTextField: UITextField = {
        let textField = AppTextField()
        
        textField.placeholder = "http://"
        textField.text = "http://"
        textField.textColor = .white
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        textField.layer.cornerRadius = 10
        textField.clipsToBounds = true
        
        textField.setContentHuggingPriority(.init(rawValue: 0), for: .horizontal)
        
        return textField
    }()
    
    private lazy var baseURLStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            self.urlActionMenuButton,
            self.baseURLTextField
        ])
        
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return UIView.insertHeader(stackView, text: "Request")
    }()
    
    private lazy var queryKeyValuesView: AppKeyValuesStackView = {
        let view = AppKeyValuesStackView(addButtonTitle: "Add Param")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var queryContentView: UIStackView = {
        let view = UIView.insertHeader(self.queryKeyValuesView, text: "Query Params")
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var headerKeyValuesView: AppKeyValuesStackView = {
        let view = AppKeyValuesStackView(addButtonTitle: "Add Header")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerContentView: UIStackView = {
        let view = UIView.insertHeader(self.headerKeyValuesView, text: "Headers")
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .appButtonColor
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 10
        
        return button
    }()
    
    private lazy var sendButtonContainer: UIView = {
        let view = UIView()
        
        view.addSubview(self.sendButton)
        
        self.sendButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(50)
            make.trailing.equalToSuperview().offset(-50)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview()
        }
        
        return view
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            self.baseURLStackView,
            self.queryContentView,
            self.headerContentView,
            self.sendButtonContainer
        ])
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 20
        
        return stackView
    }()
    
    private lazy var contentScrollView: UIScrollView = {
        return UIScrollView()
    }()
    
    init(request: Request) {
        self.request = request
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Request"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem = backButton
        
        view.addSubview(contentStackView)
        view.backgroundColor = .black
        
        contentStackView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
        }
        
        let (response, importRequest) = MainViewModel(
            inputRequest: .just(request),
            networkProvider: .just(NetworkProviderCurrent),
            fileProvider: .just(FileProviderCurrent),
            responseParser: .just(ResponseParserCurrent),
            sendRequest: self.sendButton.rx.controlEvent(.touchUpInside).asObservable(),
            baseURL: self.baseURLTextField.rx.text.orEmpty.asObservable(),
            queryParams: self.queryKeyValuesView.rx.keyValues,
            headers: self.queryKeyValuesView.rx.keyValues,
            method: .just(.get)
        )

        self.disposeBag.insert(
            response.bindOnMain(onNext: { [weak self] (response) in
                self?.presentResponseViewController(response)
            }),
            importRequest.bindOnMain(onNext: { (request) in
                self.baseURLTextField.text = request.baseURL
                self.queryKeyValuesView.importKeyValuesPublisher.onNext(request.queryParams)
                self.headerKeyValuesView.importKeyValuesPublisher.onNext(request.headers)
                self.urlActionMenuButton.setTitle(request.method.rawValue, for: .normal)
            })
        )
    }
    
    @objc func close() {
        navigationController?.popViewController(animated: true)
    }
    
    func presentResponseViewController(_ response: Response) {
        let vc = ResponseViewController(response: response)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

